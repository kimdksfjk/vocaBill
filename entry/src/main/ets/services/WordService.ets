import { relationalStore } from '@kit.ArkData';
import { Word, StudyStats, StudyRecord, StudiedWordItem, NewWord, FamiliarityDistData, DayStats } from '../models/Word';
import { DatabaseManager } from './database/DatabaseManager';
import { WordRepository } from './database/WordRepository';
import { ReviewRepository, NewReviewRecord } from './database/ReviewRepository';
import { SettingsRepository } from './database/SettingsRepository';
import { Scheduler } from './scheduler/Scheduler';
import { isDueForReview } from './scheduler/MemoryAlgorithm';
import { getTodayStart, formatDate } from '../utils/TimeUtil';
import { WordSeeder } from './WordSeeder';

/**
 * 数据服务 — 桥接 UI 层与数据库层
 */
export class WordService {
  private static wordRepo: WordRepository = new WordRepository();
  private static reviewRepo: ReviewRepository = new ReviewRepository();
  private static settingsRepo: SettingsRepository = new SettingsRepository();
  private static scheduler: Scheduler = new Scheduler();
  private static isSeeded: boolean = false;

  // ==================== 种子数据 ====================

  static async ensureSeeded(): Promise<void> {
    if (WordService.isSeeded) {
      return;
    }
    try {
      const count = await WordService.wordRepo.getWordCount();
      if (count === 0) {
        const context = DatabaseManager.getInstance().getContext();
        if (context) {
          const firstBatch = await WordSeeder.loadNextBatch(context, WordSeeder.BATCH_SIZE);
          if (firstBatch.length > 0) {
            await WordService.wordRepo.batchInsert(firstBatch);
          }
        }
      }
    } catch (err) {
      // 忽略
    }
    WordService.isSeeded = true;
  }

  // ==================== 单词相关接口 ====================

  /**
   * 获取今日待学单词：
   * 1. 包含到期需要复习的旧单词（有 nextReviewTime 且已到时间的）
   * 2. 再补充未学过的新单词
   */
  static async getTodayWords(): Promise<Word[]> {
    await WordService.ensureSeeded();
    const todayStart = getTodayStart();
    const todayIds = await WordService.reviewRepo.getTodayWordIdList(todayStart);
    const allWords = await WordService.wordRepo.getAllWords();

    const result: Word[] = [];

    // 1. 到期复习词：有 nextReviewTime 且已到时间，今天还没学过
    const dueForReview = allWords.filter((w: Word) => {
      return w.nextReviewTime > 0 && w.nextReviewTime <= Date.now() && todayIds.indexOf(w.id) === -1;
    });
    result.push(...dueForReview);

    // 2. 未学习的全新单词
    const unstudied = allWords.filter((w: Word) => {
      return w.familiarity === 0 && w.nextReviewTime === 0 && todayIds.indexOf(w.id) === -1;
    });

    const remaining = WordSeeder.BATCH_SIZE - result.length;
    if (remaining > 0) {
      // 如果未学新词不够，从 seeder 加载更多
      if (unstudied.length < remaining) {
        const context = DatabaseManager.getInstance().getContext();
        if (context) {
          const newWords = await WordSeeder.loadNextBatch(context, WordSeeder.BATCH_SIZE);
          if (newWords.length > 0) {
            await WordService.wordRepo.batchInsert(newWords);
            const freshWords = await WordService.wordRepo.getAllWords();
            const freshUnstudied = freshWords.filter((w: Word) => {
              return w.familiarity === 0 && w.nextReviewTime === 0 && todayIds.indexOf(w.id) === -1;
            });
            result.push(...freshUnstudied.slice(0, remaining));
          }
        }
      } else {
        result.push(...unstudied.slice(0, remaining));
      }
    }

    return result.slice(0, WordSeeder.BATCH_SIZE);
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

  // ==================== 学习记录接口 ====================

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

      // 更新 user_progress 表
      await WordService.updateTodayProgress();

      return true;
    } catch (err) {
      console.error(`[WordService] recordBatchResults 失败: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /** 同步今日学习进度到 user_progress 表 */
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
        // 今日记录不存在，先获取当前的 targetCount
        const existingGoal = await WordService.getDailyGoal();
        const insertBucket: relationalStore.ValuesBucket = {
          'date': todayStr,
          'studiedCount': stats.studiedCount,
          'targetCount': existingGoal,
          'accuracy': stats.studiedCount > 0 ? stats.correctCount / stats.studiedCount : 0
        };
        await store.insert('user_progress', insertBucket);
      }
    } catch (err) {
      console.error(`[WordService] updateTodayProgress 失败: ${JSON.stringify(err)}`);
    }
  }

  // ==================== 统计相关接口 ====================

  static async getStudyStats(): Promise<StudyStats> {
    try {
      const todayStart = getTodayStart();
      const todayStats = await WordService.reviewRepo.getTodayUniqueStats(todayStart);
      // totalCount: 已学过的唯一单词数
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

  /** 获取熟悉度分布 */
  static async getFamiliarityDist(): Promise<FamiliarityDistData> {
    try {
      const dist = await WordService.wordRepo.getFamiliarityDist();
      return {
        unlearned: dist.unlearned,
        unknown: dist.unknown,
        fuzzy: dist.fuzzy,
        known: dist.known
      };
    } catch (err) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
  }

  /** 获取最近7天趋势 */
  static async getWeeklyStats(): Promise<DayStats[]> {
    return await WordService.reviewRepo.getWeeklyStats();
  }

  // ==================== 设置相关接口 ====================

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
      const valueBucket: relationalStore.ValuesBucket = {
        'targetCount': goal
      };

      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        const insertBucket: relationalStore.ValuesBucket = {
          'date': todayStr,
          'studiedCount': 0,
          'targetCount': goal,
          'accuracy': 0
        };
        await store.insert('user_progress', insertBucket);
      }
      return true;
    } catch (err) {
      return false;
    }
  }

  // ==================== 用户设置（学习提醒、发音等） ====================

  /** 学习提醒开关 */
  static async getReminderEnabled(): Promise<boolean> {
    return await WordService.settingsRepo.getBoolean('reminder_enabled', false);
  }

  static async setReminderEnabled(enabled: boolean): Promise<boolean> {
    return await WordService.settingsRepo.setBoolean('reminder_enabled', enabled);
  }

  /** 发音偏好：british | american */
  static async getPronunciationPref(): Promise<string> {
    return await WordService.settingsRepo.get('pronunciation', 'british');
  }

  static async setPronunciationPref(pref: string): Promise<boolean> {
    return await WordService.settingsRepo.set('pronunciation', pref);
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
      WordService.isSeeded = false;
      WordSeeder.reset();
      await WordService.ensureSeeded();
      return true;
    } catch (err) {
      return false;
    }
  }
}
