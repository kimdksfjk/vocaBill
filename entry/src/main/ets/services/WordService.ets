import { relationalStore } from '@kit.ArkData';
import { Word, StudyStats, StudyRecord, StudiedWordItem, NewWord, FamiliarityDistData, DayStats } from '../models/Word';
import { DatabaseManager } from './database/DatabaseManager';
import { WordRepository } from './database/WordRepository';
import { ReviewRepository, NewReviewRecord } from './database/ReviewRepository';
import { SettingsRepository } from './database/SettingsRepository';
import { Scheduler } from './scheduler/Scheduler';
import { getTodayStart, formatDate } from '../utils/TimeUtil';
import { WordSeeder, WordBank } from './WordSeeder';

/**
 * 数据服务 — 连接 UI 与数据库层
 *
 * 词库调度模型（仿 Anki / 墨墨背单词）：
 *   首次启动 → preloadFullBank() 将词库 JSON 全量写入 DB
 *   每日学习 → getTodayWords() 构建当日优先队列：
 *     1. 到期复习词（nextReviewTime 已到且今天没学过）
 *     2. 全新词（familiarity=0, nextReviewTime=0 且今天没学过）
 *   学习完成 → recordBatchResults() 持久化 SRS 调度结果
 */
export class WordService {
  private static wordRepo: WordRepository = new WordRepository();
  private static reviewRepo: ReviewRepository = new ReviewRepository();
  private static settingsRepo: SettingsRepository = new SettingsRepository();
  private static scheduler: Scheduler = new Scheduler();
  private static bankReady: boolean = false;

  // ==================== 词库预加载 ====================

  /** 确保当前词库已全量预加载到 DB */
  static async preloadFullBank(): Promise<void> {
    if (WordService.bankReady) {
      return;
    }
    const count = await WordService.wordRepo.getWordCount();
    if (count > 0) {
      WordService.bankReady = true;
      return;
    }

    const context = DatabaseManager.getInstance().getContext();
    if (!context) {
      return;
    }

    const bank = await WordService.getWordBank();
    const words = await WordSeeder.loadAllWords(context, bank);
    if (words.length > 0) {
      // 批量插入（每批 200 条，避免单批过大）
      const BATCH = 200;
      for (let i = 0; i < words.length; i += BATCH) {
        const slice = words.slice(i, i + BATCH);
        await WordService.wordRepo.batchInsert(slice);
      }
      console.info(`[WordService] 词库预加载完成: ${words.length} 个单词`);
    } else {
      console.error('[WordService] 词库预加载失败：没有加载到任何单词');
    }
    WordService.bankReady = true;
  }

  // ==================== 每日学习队列 ====================

  /**
   * 获取今日待学单词
   * 优先队列：到期复习词在前，新词在后
   */
  static async getTodayWords(): Promise<Word[]> {
    // 确保词库已加载
    await WordService.preloadFullBank();

    const todayStart = getTodayStart();
    const todayIds = await WordService.reviewRepo.getTodayWordIdList(todayStart);
    const allWords = await WordService.wordRepo.getAllWords();
    const now = Date.now();

    // 总词库为空？
    if (allWords.length === 0) {
      return [];
    }

    // 1. 到期复习词：nextReviewTime > 0 且已到时间，今天还没学过
    const dueReview = allWords.filter((w: Word) => {
      return w.nextReviewTime > 0 && w.nextReviewTime <= now && todayIds.indexOf(w.id) === -1;
    });

    // 2. 全新未学词
    const newWords = allWords.filter((w: Word) => {
      return w.nextReviewTime === 0 && todayIds.indexOf(w.id) === -1;
    });

    // 优先返回复习词 + 新词，上限为每日目标
    const dailyGoal = await WordService.getDailyGoal();
    const result: Word[] = [];
    result.push(...dueReview);
    const remaining = dailyGoal - result.length;
    if (remaining > 0) {
      result.push(...newWords.slice(0, remaining));
    }

    return result;
  }

  static async getWordDetail(wordId: number): Promise<Word | undefined> {
    const word = await WordService.wordRepo.getWordById(wordId);
    return word ?? undefined;
  }

  static async getTodayStudiedWords(): Promise<StudiedWordItem[]> {
    const todayStart = getTodayStart();
    const knownMap = await WordService.reviewRepo.getTodayWordKnownMap(todayStart);
    const allWords = await WordService.wordRepo.getAllWords();
    const result: StudiedWordItem[] = [];
    knownMap.forEach((known: boolean, wordId: number) => {
      const word = allWords.find((w: Word) => w.id === wordId);
      if (word) {
        result.push({
          id: word.id,
          word: word.word,
          meaning: word.meaning,
          known: known
        });
      }
    });
    return result;
  }

  // ==================== 学习记录 ====================

  static async recordBatchResults(records: StudyRecord[]): Promise<boolean> {
    if (records.length === 0) {
      return true;
    }
    try {
      for (const record of records) {
        const reviewRecord: NewReviewRecord = {
          wordId: record.wordId,
          isKnown: record.known,
          reviewTime: record.timestamp
        };
        await WordService.reviewRepo.insert(reviewRecord);

        const word = await WordService.wordRepo.getWordById(record.wordId);
        if (word) {
          if (record.known) {
            const result = WordService.scheduler.handleKnown(word.familiarity);
            await WordService.wordRepo.updateFamiliarity(record.wordId, result.newFamiliarity, result.nextReviewTime);
          } else {
            const result = WordService.scheduler.handleUnknown();
            await WordService.wordRepo.updateFamiliarity(record.wordId, result.newFamiliarity, result.nextReviewTime);
          }
        }
      }

      await WordService.updateTodayProgress();
      return true;
    } catch (err) {
      console.error(`[WordService] recordBatchResults 失败: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /** 同步 user_progress 表 */
  private static async updateTodayProgress(): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      return;
    }
    try {
      const todayStr = formatDate(Date.now());
      const todayStart = getTodayStart();
      const stats = await WordService.reviewRepo.getTodayUniqueStats(todayStart);

      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('date', todayStr);
      const valueBucket: relationalStore.ValuesBucket = {
        'studiedCount': stats.studiedCount,
        'accuracy': stats.studiedCount > 0 ? stats.correctCount / stats.studiedCount : 0
      };
      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        const goal = await WordService.getDailyGoal();
        const insertBucket: relationalStore.ValuesBucket = {
          'date': todayStr,
          'studiedCount': stats.studiedCount,
          'targetCount': goal,
          'accuracy': stats.studiedCount > 0 ? stats.correctCount / stats.studiedCount : 0
        };
        await store.insert('user_progress', insertBucket);
      }
    } catch (err) {
      console.error(`[WordService] updateTodayProgress 失败: ${JSON.stringify(err)}`);
    }
  }

  // ==================== 统计 ====================

  static async getStudyStats(): Promise<StudyStats> {
    try {
      const todayStart = getTodayStart();
      const todayStats = await WordService.reviewRepo.getTodayUniqueStats(todayStart);
      const totalCount = await WordService.wordRepo.getStudiedWordCount();
      const dailyGoal = await WordService.getDailyGoal();

      let masteredCount = 0;
      try {
        const allWords = await WordService.wordRepo.getAllWords();
        masteredCount = allWords.filter((w: Word) => w.familiarity >= 3).length;
      } catch (_) {
        masteredCount = 0;
      }

      const correctRate = todayStats.studiedCount > 0
        ? Math.round((todayStats.correctCount / todayStats.studiedCount) * 100)
        : 0;

      return {
        todayCount: todayStats.studiedCount,
        totalCount: totalCount,
        todayGoal: dailyGoal,
        correctRate: correctRate,
        masteredCount: masteredCount
      };
    } catch (err) {
      return {
        todayCount: -1,
        totalCount: -1,
        todayGoal: 20,
        correctRate: 0,
        masteredCount: 0
      };
    }
  }

  static async getFamiliarityDist(): Promise<FamiliarityDistData> {
    try {
      return await WordService.wordRepo.getFamiliarityDist();
    } catch (err) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
  }

  static async getWeeklyStats(): Promise<DayStats[]> {
    return await WordService.reviewRepo.getWeeklyStats();
  }

  // ==================== 设置 ====================

  static async getDailyGoal(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      return 20;
    }
    try {
      const todayStr = formatDate(Date.now());
      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('date', todayStr);
      const resultSet = await store.query(predicates, ['targetCount']);
      let goal = 20;
      if (resultSet.goToNextRow()) {
        goal = resultSet.getLong(resultSet.getColumnIndex('targetCount'));
      }
      resultSet.close();
      return goal;
    } catch (err) {
      return 20;
    }
  }

  static async setDailyGoal(goal: number): Promise<boolean> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      return false;
    }
    try {
      const todayStr = formatDate(Date.now());
      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('date', todayStr);
      const valueBucket: relationalStore.ValuesBucket = { 'targetCount': goal };
      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        const bucket: relationalStore.ValuesBucket = {
          'date': todayStr,
          'studiedCount': 0,
          'targetCount': goal,
          'accuracy': 0
        };
        await store.insert('user_progress', bucket);
      }
      return true;
    } catch (err) {
      return false;
    }
  }

  // ==================== 用户偏好 ====================

  static async getReminderEnabled(): Promise<boolean> {
    return await WordService.settingsRepo.getBoolean('reminder_enabled', false);
  }

  static async setReminderEnabled(enabled: boolean): Promise<boolean> {
    return await WordService.settingsRepo.setBoolean('reminder_enabled', enabled);
  }

  static async getPronunciationPref(): Promise<string> {
    return await WordService.settingsRepo.get('pronunciation', 'british');
  }

  static async setPronunciationPref(pref: string): Promise<boolean> {
    return await WordService.settingsRepo.set('pronunciation', pref);
  }

  static async getWordBank(): Promise<WordBank> {
    const val = await WordService.settingsRepo.get('word_bank', 'cet4_cet6');
    if (val === 'cet4' || val === 'cet6' || val === 'cet4_cet6') {
      return val as WordBank;
    }
    return 'cet4_cet6';
  }

  /** 切换词库：清空旧数据 + 全量预加载新词库 */
  static async setWordBank(bank: WordBank): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store) {
      try {
        await store.executeSql('DELETE FROM review_record');
        await store.executeSql('DELETE FROM user_progress');
        await store.executeSql('DELETE FROM words');
      } catch (err) {
        console.error(`[WordService] 清空词库失败: ${JSON.stringify(err)}`);
      }
    }
    // 持久化偏好
    await WordService.settingsRepo.set('word_bank', bank);
    // 重新预加载
    WordService.bankReady = false;
    await WordService.preloadFullBank();
  }

  // ==================== 数据重置 ====================

  static async resetAllData(): Promise<boolean> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      return false;
    }
    try {
      await store.executeSql('DELETE FROM review_record');
      await store.executeSql('DELETE FROM user_progress');
      await store.executeSql('DELETE FROM words');
      WordService.bankReady = false;
      await WordService.preloadFullBank();
      return true;
    } catch (err) {
      return false;
    }
  }
}
