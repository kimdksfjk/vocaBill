import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Word } from '../../models/Word';
import { DatabaseManager } from './DatabaseManager';

const TABLE_WORDS = 'words';

/**
 * 单词数据仓库
 */
export class WordRepository {

  async batchInsert(words: Word[]): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const valueBuckets: relationalStore.ValuesBucket[] = [];
    for (const word of words) {
      const bucket: relationalStore.ValuesBucket = {
        'word': word.word,
        'meaning': word.meaning,
        'familiarity': word.familiarity
      };
      valueBuckets.push(bucket);
    }
    try {
      const count = await store.batchInsert(TABLE_WORDS, valueBuckets);
      console.info(`[WordRepository] 批量插入单词成功, 数量: ${count}`);
      return count;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 批量插入失败: ${error.message}`);
      throw new Error(`批量插入失败: ${error.message}`);
    }
  }

  async getAllWords(): Promise<Word[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      predicates.orderByAsc('id');
      const resultSet = await store.query(predicates, ['id', 'word', 'meaning', 'familiarity']);
      const words: Word[] = [];
      while (resultSet.goToNextRow()) {
        words.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          word: resultSet.getString(resultSet.getColumnIndex('word')),
          meaning: resultSet.getString(resultSet.getColumnIndex('meaning')),
          familiarity: resultSet.getLong(resultSet.getColumnIndex('familiarity'))
        });
      }
      resultSet.close();
      return words;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 查询单词失败: ${error.message}`);
      throw new Error(`查询单词失败: ${error.message}`);
    }
  }

  async getWordById(id: number): Promise<Word | null> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      predicates.equalTo('id', id);
      const resultSet = await store.query(predicates, ['id', 'word', 'meaning', 'familiarity']);
      let word: Word | null = null;
      if (resultSet.goToNextRow()) {
        word = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          word: resultSet.getString(resultSet.getColumnIndex('word')),
          meaning: resultSet.getString(resultSet.getColumnIndex('meaning')),
          familiarity: resultSet.getLong(resultSet.getColumnIndex('familiarity'))
        };
      }
      resultSet.close();
      return word;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 查询单词失败: ${error.message}`);
      throw new Error(`查询单词失败: ${error.message}`);
    }
  }

  async updateFamiliarity(id: number, familiarity: number): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'familiarity': familiarity
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      predicates.equalTo('id', id);
      const rows = await store.update(valueBucket, predicates);
      console.info(`[WordRepository] 更新熟悉度成功, 影响行数: ${rows}`);
      return rows;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 更新熟悉度失败: ${error.message}`);
      throw new Error(`更新熟悉度失败: ${error.message}`);
    }
  }

  async getWordCount(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      const resultSet = await store.query(predicates, ['id']);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 获取单词总数失败: ${error.message}`);
      throw new Error(`获取单词总数失败: ${error.message}`);
    }
  }
}
