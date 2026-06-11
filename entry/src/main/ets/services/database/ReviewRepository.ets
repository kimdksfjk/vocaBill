import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { DayStats } from '../../models/Word';
import { DatabaseManager } from './DatabaseManager';
import { formatDate } from '../../utils/TimeUtil';

const TABLE_REVIEW_RECORD = 'review_record';

export interface NewReviewRecord {
  wordId: number;
  userId: number;
  isKnown: boolean;
  reviewTime: number;
}

export class TodayStats {
  studiedCount: number = 0;
  correctCount: number = 0;

  constructor(studiedCount: number, correctCount: number) {
    this.studiedCount = studiedCount;
    this.correctCount = correctCount;
  }
}

export class ReviewRepository {

  async batchInsert(records: NewReviewRecord[]): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBuckets: relationalStore.ValuesBucket[] = [];
      for (const record of records) {
        valueBuckets.push({
          'userId': record.userId,
          'wordId': record.wordId,
          'isKnown': record.isKnown ? 1 : 0,
          'reviewTime': record.reviewTime
        });
      }
      await store.batchInsert(TABLE_REVIEW_RECORD, valueBuckets);
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`批量插入学习记录失败: ${error.message}`);
    }
  }

  async getTodayWordIdList(userId: number, todayStart: number): Promise<number[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const idList: number[] = [];
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.equalTo('userId', userId);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart);
      const resultSet = await store.query(predicates, ['wordId']);
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('wordId'));
        if (idList.indexOf(id) === -1) {
          idList.push(id);
        }
      }
      resultSet.close();
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`获取今日单词ID失败: ${error.message}`);
    }
    return idList;
  }

  async getTodayWordKnownMap(userId: number, todayStart: number): Promise<Map<number, boolean>> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const map: Map<number, boolean> = new Map<number, boolean>();
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.equalTo('userId', userId);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart);
      const resultSet = await store.query(predicates, ['wordId', 'isKnown']);
      while (resultSet.goToNextRow()) {
        const wordId = resultSet.getLong(resultSet.getColumnIndex('wordId'));
        const isKnown = resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1;
        if (!map.has(wordId)) {
          map.set(wordId, isKnown);
        } else if (isKnown) {
          map.set(wordId, true);
        }
      }
      resultSet.close();
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`获取今日单词状态失败: ${error.message}`);
    }
    return map;
  }

  async getTodayUniqueStats(userId: number, todayStart: number): Promise<TodayStats> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.equalTo('userId', userId);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart);
      const resultSet = await store.query(predicates, ['wordId', 'isKnown']);
      const seenIds: number[] = [];
      const knownFlags: boolean[] = [];
      while (resultSet.goToNextRow()) {
        const wordId = resultSet.getLong(resultSet.getColumnIndex('wordId'));
        const isKnown = resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1;
        const idx = seenIds.indexOf(wordId);
        if (idx === -1) {
          seenIds.push(wordId);
          knownFlags.push(isKnown);
        } else {
          if (isKnown && !knownFlags[idx]) {
            knownFlags[idx] = true;
          }
        }
      }
      resultSet.close();
      let correctCount = 0;
      for (let i = 0; i < knownFlags.length; i++) {
        if (knownFlags[i]) {
          correctCount++;
        }
      }
      return new TodayStats(seenIds.length, correctCount);
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`去重统计失败: ${error.message}`);
    }
  }

  async getWeeklyStats(userId: number): Promise<DayStats[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return [];
    }
    try {
      const today = new Date();
      const result: DayStats[] = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - i);
        const dateStr = formatDate(d.getTime());
        const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
        const dayEnd = dayStart + 24 * 60 * 60 * 1000;

        const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
        predicates.equalTo('userId', userId);
        predicates.greaterThanOrEqualTo('reviewTime', dayStart);
        predicates.lessThan('reviewTime', dayEnd);
        const resultSet = await store.query(predicates, ['wordId', 'isKnown']);

        const seenIds: number[] = [];
        const knownFlags: boolean[] = [];
        while (resultSet.goToNextRow()) {
          const wordId = resultSet.getLong(resultSet.getColumnIndex('wordId'));
          const isKnown = resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1;
          const idx = seenIds.indexOf(wordId);
          if (idx === -1) {
            seenIds.push(wordId);
            knownFlags.push(isKnown);
          } else {
            if (isKnown && !knownFlags[idx]) {
              knownFlags[idx] = true;
            }
          }
        }
        resultSet.close();

        let correctCount = 0;
        for (let k = 0; k < knownFlags.length; k++) {
          if (knownFlags[k]) {
            correctCount++;
          }
        }
        const count = seenIds.length;
        const correctRate = count > 0 ? Math.round((correctCount / count) * 100) : 0;
        const dayStat: DayStats = { date: dateStr, count: count, correctRate: correctRate };
        result.push(dayStat);
      }
      return result;
    } catch (err) {
      console.error(`[ReviewRepository] 获取周统计失败: ${JSON.stringify(err)}`);
      return [];
    }
  }
}
