import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReviewRecord } from '../../models/ReviewRecord';
import { DatabaseManager } from './DatabaseManager';

const TABLE_REVIEW_RECORD = 'review_record';

/**
 * 学习记录数据仓库
 * 负责学习记录的保存与查询
 */
export class ReviewRepository {

  /**
   * 保存一条学习记录
   * @param record 学习记录（不含id）
   * @returns 插入的行ID
   */
  async insert(record: Omit<ReviewRecord, 'id'>): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'wordId': record.wordId,
        'isKnown': record.isKnown ? 1 : 0,
        'reviewTime': record.reviewTime
      };
      const rowId = await store.insert(TABLE_REVIEW_RECORD, valueBucket);
      console.info(`[ReviewRepository] 插入学习记录成功, rowId: ${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[ReviewRepository] 插入学习记录失败: ${error.message}`);
      throw err;
    }
  }

  /**
   * 获取某单词的所有学习记录
   * @param wordId 单词ID
   */
  async getByWordId(wordId: number): Promise<ReviewRecord[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.equalTo('wordId', wordId).orderByDesc('reviewTime');
      const resultSet = await store.query(predicates,
        ['id', 'wordId', 'isKnown', 'reviewTime']);
      const records: ReviewRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          wordId: resultSet.getLong(resultSet.getColumnIndex('wordId')),
          isKnown: resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1,
          reviewTime: resultSet.getLong(resultSet.getColumnIndex('reviewTime'))
        });
      }
      resultSet.close();
      return records;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[ReviewRepository] 查询学习记录失败: ${error.message}`);
      throw err;
    }
  }

  /**
   * 获取今日学习记录
   * @param todayStart 今日起始时间戳（毫秒）
   */
  async getTodayRecords(todayStart: number): Promise<ReviewRecord[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart).orderByDesc('reviewTime');
      const resultSet = await store.query(predicates,
        ['id', 'wordId', 'isKnown', 'reviewTime']);
      const records: ReviewRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          wordId: resultSet.getLong(resultSet.getColumnIndex('wordId')),
          isKnown: resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1,
          reviewTime: resultSet.getLong(resultSet.getColumnIndex('reviewTime'))
        });
      }
      resultSet.close();
      return records;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[ReviewRepository] 查询今日记录失败: ${error.message}`);
      throw err;
    }
  }

  /**
   * 获取今日学习统计
   * @param todayStart 今日起始时间戳（毫秒）
   * @returns { studiedCount: 已学数量, correctCount: 认识的数量 }
   */
  async getTodayStats(todayStart: number):
    Promise<{ studiedCount: number; correctCount: number }> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_REVIEW_RECORD);
      predicates.greaterThanOrEqualTo('reviewTime', todayStart);
      const resultSet = await store.query(predicates, ['isKnown']);
      let studiedCount = 0;
      let correctCount = 0;
      while (resultSet.goToNextRow()) {
        studiedCount++;
        if (resultSet.getLong(resultSet.getColumnIndex('isKnown')) === 1) {
          correctCount++;
        }
      }
      resultSet.close();
      return { studiedCount, correctCount };
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[ReviewRepository] 统计查询失败: ${error.message}`);
      throw err;
    }
  }

  /**
   * 累计学习总量
   */
  async getTotalCount(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
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
      console.error(`[ReviewRepository] 获取总量失败: ${error.message}`);
      throw err;
    }
  }
}
