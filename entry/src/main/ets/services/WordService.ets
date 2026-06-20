import { relationalStore } from '@kit.ArkData';
import { Word, WordWithState, StudyStats, StudyRecord, StudiedWordItem, FamiliarityDistData, DayStats } from '../models/Word';
import { DatabaseManager } from './database/DatabaseManager';
import { WordRepository } from './database/WordRepository';
import { ReviewRepository, NewReviewRecord } from './database/ReviewRepository';
import { SettingsRepository } from './database/SettingsRepository';
import { Scheduler } from './scheduler/Scheduler';
import { getTodayStart, formatDate } from '../utils/TimeUtil';
import { WordSeeder, WordBank } from './WordSeeder';
import { UserService } from './UserService';

export class WordService {
  private static wordRepo: WordRepository = new WordRepository();
  private static reviewRepo: ReviewRepository = new ReviewRepository();
  private static settingsRepo: SettingsRepository = new SettingsRepository();
  private static scheduler: Scheduler = new Scheduler();
  private static bankReady: boolean = false;

  /** 获取当前用户 ID（调用方需保证已登录） */
  private static async getUserId(): Promise<number> {
    const id = await UserService.getCurrentUserId();
    if (id === null) {
      throw new Error('用户未登录');
    }
    return id;
  }

  // ==================== 词库预加载 ====================

  static async preloadFullBank(): Promise<void> {
    if (WordService.bankReady) return;
    const count = await WordService.wordRepo.getWordCount();
    if (count > 0) {
      WordService.bankReady = true;
      return;
    }
    const context = DatabaseManager.getInstance().getContext();
    if (!context) return;
    const bank = await WordService.getWordBank();
    const words = await WordSeeder.loadAllWords(context, bank);
    if (words.length > 0) {
      const BATCH = 200;
      for (let i = 0; i < words.length; i += BATCH) {
        await WordService.wordRepo.batchInsert(words.slice(i, i + BATCH));
      }
    }
    WordService.bankReady = true;
  }

  // ==================== 每日学习队列 ====================

  static async getTodayWords(): Promise<WordWithState[]> {
    await WordService.preloadFullBank();
    const userId = await WordService.getUserId();
    const todayStart = getTodayStart();
    const todayIds = await WordService.reviewRepo.getTodayWordIdList(userId, todayStart);
    const allWords = await WordService.wordRepo.getAllWordsWithState(userId);
    const now = Date.now();

    if (allWords.length === 0) return [];

    // 1. 到期复习词
    const dueReview = allWords.filter((w: WordWithState) => {
      return w.nextReviewTime > 0 && w.nextReviewTime <= now && todayIds.indexOf(w.id) === -1;
    });

    // 2. 全新未学词
    const newWords = allWords.filter((w: WordWithState) => {
      return w.nextReviewTime === 0 && todayIds.indexOf(w.id) === -1;
    });

    // 每组 10 个，优先复习
    const GROUP_SIZE = 10;
    const result: WordWithState[] = [];
    result.push(...dueReview.slice(0, GROUP_SIZE));
    const remaining = GROUP_SIZE - result.length;
    if (remaining > 0) {
      // 随机打乱全新未学词
      for (let i = newWords.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        const temp = newWords[i];
        newWords[i] = newWords[j];
        newWords[j] = temp;
      }
      result.push(...newWords.slice(0, remaining));
    }
    return result;
  }

  static async getWordDetail(wordId: number): Promise<Word | undefined> {
    const word = await WordService.wordRepo.getWordById(wordId);
    return word ?? undefined;
  }

  static async generateOptionsForWord(word: WordWithState): Promise<string[]> {
    const match = word.meaning.match(/^([a-z]+)\./);
    const pos = match ? match[1] + '.' : '';
    let incorrectOptions: string[] = [];
    if (pos) {
      incorrectOptions = await WordService.wordRepo.getRandomMeaningsByPos(pos, word.id, 3);
    }
    
    if (incorrectOptions.length < 3) {
      const extraNeeded = 3 - incorrectOptions.length;
      const extraOptions = await WordService.wordRepo.getRandomMeanings(word.id, extraNeeded);
      incorrectOptions.push(...extraOptions);
    }

    const options = [word.meaning, ...incorrectOptions];
    return options.sort(() => Math.random() - 0.5);
  }

  static async getTodayStudiedWords(): Promise<StudiedWordItem[]> {
    const userId = await WordService.getUserId();
    const todayStart = getTodayStart();
    const knownMap = await WordService.reviewRepo.getTodayWordKnownMap(userId, todayStart);
    const result: StudiedWordItem[] = [];
    const entries: Array<[number, boolean]> = [];
    knownMap.forEach((value: boolean, key: number) => {
      entries.push([key, value]);
    });
    for (let i = 0; i < entries.length; i++) {
      const wordId = entries[i][0];
      const known = entries[i][1];
      const word = await WordService.wordRepo.getWordById(wordId);
      if (word) {
        result.push({ id: word.id, word: word.word, meaning: word.meaning, known: known });
      }
    }
    return result;
  }

  // ==================== 学习记录 ====================

  static async recordBatchResults(records: StudyRecord[]): Promise<boolean> {
    if (records.length === 0) return true;
    const userId = await WordService.getUserId();
    try {
      // 收集所有记录，批量插入复习记录
      const reviewRecords: NewReviewRecord[] = [];
      for (let ri = 0; ri < records.length; ri++) {
        const r = records[ri];
        const rec: NewReviewRecord = {
          userId: userId,
          wordId: r.wordId,
          isKnown: r.known,
          reviewTime: r.timestamp
        };
        reviewRecords.push(rec);
      }
      await WordService.reviewRepo.batchInsert(reviewRecords);

      // 逐个更新词状态
      // 先获取所有词的状态（避免逐条查询）
      const allStates = await WordService.wordRepo.getAllWordsWithState(userId);
      for (const record of records) {
        const state = allStates.find((w: WordWithState) => w.id === record.wordId);
        const currentFam = state ? state.familiarity : 0;

        let newFam: number;
        let nextTime: number;
        if (record.known) {
          const schedResult = WordService.scheduler.handleKnown(currentFam);
          nextTime = schedResult.nextReviewTime;
        } else {
          const schedResult = WordService.scheduler.handleUnknown();
          nextTime = schedResult.nextReviewTime;
        }

        if (record.mode === 'Deep') {
          newFam = record.known ? 2 : 1;
        } else if (record.mode === 'Casual') {
          newFam = record.known ? 3 : 0;
        } else {
          newFam = record.known ? WordService.scheduler.handleKnown(currentFam).newFamiliarity : WordService.scheduler.handleUnknown().newFamiliarity;
        }
        await WordService.wordRepo.upsertWordState(userId, record.wordId, newFam, nextTime);
      }
      await WordService.updateTodayProgress(userId);
      return true;
    } catch (err) {
      console.error(`[WordService] recordBatchResults 失败: ${JSON.stringify(err)}`);
      return false;
    }
  }

  private static async updateTodayProgress(userId: number): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;
    try {
      const todayStr = formatDate(Date.now());
      const todayStart = getTodayStart();
      const stats = await WordService.reviewRepo.getTodayUniqueStats(userId, todayStart);

      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('userId', userId);
      predicates.equalTo('date', todayStr);
      const valueBucket: relationalStore.ValuesBucket = {
        'studiedCount': stats.studiedCount,
        'accuracy': stats.studiedCount > 0 ? stats.correctCount / stats.studiedCount : 0
      };
      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        await store.insert('user_progress', {
          'userId': userId,
          'date': todayStr,
          'studiedCount': stats.studiedCount,
          'targetCount': 20,
          'accuracy': stats.studiedCount > 0 ? stats.correctCount / stats.studiedCount : 0
        });
      }
    } catch (err) {
      console.error(`[WordService] updateTodayProgress 失败: ${JSON.stringify(err)}`);
    }
  }

  // ==================== 统计 ====================

  static async getStudyStats(): Promise<StudyStats> {
    try {
      const userId = await WordService.getUserId();
      const todayStart = getTodayStart();
      const todayStats = await WordService.reviewRepo.getTodayUniqueStats(userId, todayStart);
      const totalCount = await WordService.wordRepo.getStudiedWordCount(userId);
      const dailyGoal = await WordService.getDailyGoal();

      let masteredCount = 0;
      try {
        const allWords = await WordService.wordRepo.getAllWordsWithState(userId);
        masteredCount = allWords.filter((w: WordWithState) => w.familiarity >= 3).length;
      } catch (_) {
        masteredCount = 0;
      }

      const correctRate = todayStats.studiedCount > 0
        ? Math.round((todayStats.correctCount / todayStats.studiedCount) * 100) : 0;

      return {
        todayCount: todayStats.studiedCount,
        totalCount: totalCount,
        todayGoal: dailyGoal,
        correctRate: correctRate,
        masteredCount: masteredCount
      };
    } catch (err) {
      return { todayCount: -1, totalCount: -1, todayGoal: 20, correctRate: 0, masteredCount: 0 };
    }
  }

  static async getFamiliarityDist(): Promise<FamiliarityDistData> {
    try {
      const userId = await WordService.getUserId();
      return await WordService.wordRepo.getFamiliarityDist(userId);
    } catch (err) {
      return { unlearned: 0, fuzzy: 0, known: 0, trueVocab: 0 };
    }
  }

  static async getWeeklyStats(): Promise<DayStats[]> {
    const userId = await WordService.getUserId();
    return await WordService.reviewRepo.getWeeklyStats(userId);
  }

  // ==================== 设置 ====================

  static async getDailyGoal(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return 20;
    try {
      const userId = await WordService.getUserId();
      const todayStr = formatDate(Date.now());
      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('userId', userId);
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
    if (!store) return false;
    try {
      const userId = await WordService.getUserId();
      const todayStr = formatDate(Date.now());
      const predicates = new relationalStore.RdbPredicates('user_progress');
      predicates.equalTo('userId', userId);
      predicates.equalTo('date', todayStr);
      const rows = await store.update({ 'targetCount': goal }, predicates);
      if (rows === 0) {
        await store.insert('user_progress', { 'userId': userId, 'date': todayStr, 'studiedCount': 0, 'targetCount': goal, 'accuracy': 0 });
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
    if (val === 'cet4' || val === 'cet6' || val === 'cet4_cet6') return val as WordBank;
    return 'cet4_cet6';
  }

  static async setWordBank(bank: WordBank): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store) {
      try {
        await store.executeSql('DELETE FROM review_record');
        await store.executeSql('DELETE FROM user_word_state');
        await store.executeSql('DELETE FROM user_progress');
        await store.executeSql('DELETE FROM words');
      } catch (err) {
        console.error(`[WordService] 清空词库失败: ${JSON.stringify(err)}`);
      }
    }
    await WordService.settingsRepo.set('word_bank', bank);
    WordService.bankReady = false;
    await WordService.preloadFullBank();
  }

  // ==================== 数据重置 ====================

  static async resetAllData(): Promise<boolean> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return false;
    try {
      await store.executeSql('DELETE FROM review_record');
      await store.executeSql('DELETE FROM user_word_state');
      await store.executeSql('DELETE FROM user_progress');
      WordService.bankReady = true;  // words 表不动，只清用户进度
      return true;
    } catch (err) {
      return false;
    }
  }
}
