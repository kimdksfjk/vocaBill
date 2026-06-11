import { relationalStore } from '@kit.ArkData';
import { Word, StudyStats, StudyRecord, StudiedWordItem } from '../models/Word';
import { DatabaseManager } from './database/DatabaseManager';
import { WordRepository } from './database/WordRepository';
import { ReviewRepository, NewReviewRecord } from './database/ReviewRepository';
import { Scheduler } from './scheduler/Scheduler';
import { getTodayStart, formatDate } from '../utils/TimeUtil';

/** 首次使用时的种子词库 */
const SEED_WORDS: Word[] = [
  { id: 0, word: 'abandon', meaning: 'v. 放弃；抛弃', familiarity: 0 },
  { id: 0, word: 'brilliant', meaning: 'adj. 杰出的；明亮的', familiarity: 0 },
  { id: 0, word: 'curious', meaning: 'adj. 好奇的；奇特的', familiarity: 0 },
  { id: 0, word: 'demonstrate', meaning: 'v. 证明；演示', familiarity: 0 },
  { id: 0, word: 'enthusiasm', meaning: 'n. 热情；热心', familiarity: 0 },
  { id: 0, word: 'flexible', meaning: 'adj. 灵活的；易弯曲的', familiarity: 0 },
  { id: 0, word: 'generous', meaning: 'adj. 慷慨的；大方的', familiarity: 0 },
  { id: 0, word: 'hesitate', meaning: 'v. 犹豫；迟疑', familiarity: 0 },
  { id: 0, word: 'illustrate', meaning: 'v. 阐明；举例说明', familiarity: 0 },
  { id: 0, word: 'journey', meaning: 'n. 旅程；旅行', familiarity: 0 },
];

/**
 * 数据服务 — 前端UI与成员B数据库层的桥接
 * 所有方法均为 static async，页面通过 .then() 或 await 调用
 */
export class WordService {
  private static wordRepo: WordRepository = new WordRepository();
  private static reviewRepo: ReviewRepository = new ReviewRepository();
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
        await WordService.wordRepo.batchInsert(SEED_WORDS);
      }
    } catch (err) {
      // 忽略，实际调用时再处理
    }
    WordService.isSeeded = true;
  }

  // ==================== 单词相关接口 ====================

  static async getTodayWords(): Promise<Word[]> {
    await WordService.ensureSeeded();
    const allWords = await WordService.wordRepo.getAllWords();
    // 过滤掉今天已经学过的单词
    const todayStart = getTodayStart();
    const todayIds = await WordService.reviewRepo.getTodayWordIdList(todayStart);
    return allWords.filter((w: Word) => todayIds.indexOf(w.id) === -1);
  }

  static async getWordDetail(wordId: number): Promise<Word | undefined> {
    const word = await WordService.wordRepo.getWordById(wordId);
    return word ?? undefined;
  }

  /** 获取今日已学单词列表（含认识/不认识状态） */
  static async getTodayStudiedWords(): Promise<StudiedWordItem[]> {
    const todayStart = getTodayStart();
    const knownMap = await WordService.reviewRepo.getTodayWordKnownMap(todayStart);
    const allWords = await WordService.wordRepo.getAllWords();
    const result: StudiedWordItem[] = [];
    // 只收集今日已学的单词
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
            await WordService.wordRepo.updateFamiliarity(record.wordId, result.newFamiliarity);
          } else {
            const result = WordService.scheduler.handleUnknown();
            await WordService.wordRepo.updateFamiliarity(record.wordId, result.newFamiliarity);
          }
        }
      }
      return true;
    } catch (err) {
      return false;
    }
  }

  // ==================== 统计相关接口 ====================

  static async getStudyStats(): Promise<StudyStats> {
    try {
      const todayStart = getTodayStart();
      // 使用去重统计：同一单词学多次只算一次
      const todayStats = await WordService.reviewRepo.getTodayUniqueStats(todayStart);
      const totalCount = await WordService.reviewRepo.getTotalCount();
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
        todayCount: -1,   // 用 -1 标记失败，让 UI 知道不是"无变化"而是"加载失败"
        totalCount: -1,
        todayGoal: 20,
        correctRate: 0,
        masteredCount: 0
      };
    }
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
      await WordService.ensureSeeded();
      return true;
    } catch (err) {
      return false;
    }
  }
}
