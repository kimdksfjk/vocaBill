import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReviewRecord } from '../../models/ReviewRecord';
import { DatabaseManager } from './DatabaseManager';

const TABLE_REVIEW_RECORD = 'review_record';

/** 复习记录插入参数（不含自增id） */
export interface NewReviewRecord {
  wordId: number;
  isKnown: boolean;
  reviewTime: number;
}

/** 今日学习统计 */
export class TodayStats {
  studiedCount: number = 0;
  correctCount: number = 0;

  constructor(studiedCount: number, correctCount: number) {
    this.studiedCount = studiedCount;
    this.correctCount = correctCount;
  }
}

/**
 * 学习记录数据仓库
 */
export class ReviewRepository {

  async insert(record: NewReviewRecord): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'wordId': record.wordId,
        'isKnown': record.isKnown ? 1 : 0,
        'reviewTime': record.reviewTime
      };
      const rowId = await store.insert(TABLE_REVIEW_RECORD, valueBucket);
      return rowId;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`插入学习记录失败: ${error.message}`);
    }
  }

  /** 获取今日已学单词ID列表（去重） */
  async getTodayWordIdList(todayStart: number): Promise<number[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const idList: number[] = [];
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
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

  /** 获取今日已学单词ID→是否认识的映射（任一认识即标记认识） */
  async getTodayWordKnownMap(todayStart: number): Promise<Map<number, boolean>> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const map = new Map<number, boolean>();
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
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

  /** 获取今日去重后的学习与正确统计 */
  async getTodayUniqueStats(todayStart: number): Promise<TodayStats> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart);
      const resultSet = await store.query(predicates, ['wordId', 'isKnown']);
      // 用两个数组分别记录已经见过的 wordId 和是否认识过
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
          // 任一一次认识就算认识
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

  async getTotalCount(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      const resultSet = await store.query(predicates, ['id']);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`获取总量失败: ${error.message}`);
    }
  }
}
