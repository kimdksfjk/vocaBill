import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Word, NewWord, FamiliarityDistData } from '../../models/Word';
import { DatabaseManager } from './DatabaseManager';

const TABLE_WORDS = 'words';

/**
 * 单词数据仓库
 */
export class WordRepository {

  async batchInsert(words: NewWord[]): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    const valueBuckets: relationalStore.ValuesBucket[] = [];
    for (const w of words) {
      const bucket: relationalStore.ValuesBucket = {
        'word': w.word,
        'meaning': w.meaning,
        'familiarity': w.familiarity,
        'nextReviewTime': w.nextReviewTime,
        'usPhonetic': w.usPhonetic,
        'ukPhonetic': w.ukPhonetic,
        'exampleSentence': w.exampleSentence
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
      const resultSet = await store.query(predicates,
        ['id', 'word', 'meaning', 'familiarity', 'nextReviewTime', 'usPhonetic', 'ukPhonetic', 'exampleSentence']);
      const words: Word[] = [];
      while (resultSet.goToNextRow()) {
        words.push(WordRepository.rowToWord(resultSet));
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
      const resultSet = await store.query(predicates,
        ['id', 'word', 'meaning', 'familiarity', 'nextReviewTime', 'usPhonetic', 'ukPhonetic', 'exampleSentence']);
      let word: Word | null = null;
      if (resultSet.goToNextRow()) {
        word = WordRepository.rowToWord(resultSet);
      }
      resultSet.close();
      return word;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[WordRepository] 查询单词失败: ${error.message}`);
      throw new Error(`查询单词失败: ${error.message}`);
    }
  }

  async updateFamiliarity(id: number, familiarity: number, nextReviewTime?: number): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'familiarity': familiarity
      };
      if (nextReviewTime !== undefined) {
        valueBucket['nextReviewTime'] = nextReviewTime;
      }
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      predicates.equalTo('id', id);
      const rows = await store.update(valueBucket, predicates);
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

  /** 获取已学习过的唯一单词数（在 review_record 中有记录的） */
  async getStudiedWordCount(): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return 0;
    }
    try {
      const sql = 'SELECT COUNT(DISTINCT wordId) AS cnt FROM review_record';
      const resultSet = await store.querySql(sql);
      let count = 0;
      if (resultSet.goToNextRow()) {
        count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
      }
      resultSet.close();
      return count;
    } catch (err) {
      return 0;
    }
  }

  /** 获取熟悉度分布统计 */
  async getFamiliarityDist(): Promise<FamiliarityDistData> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
    try {
      const result: FamiliarityDistData =
        { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
      // 0=unlearned, 1=unknown, 2=fuzzy, 3=known
      const sql = `SELECT familiarity, COUNT(*) AS cnt FROM ${TABLE_WORDS} GROUP BY familiarity`;
      const resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const fam = resultSet.getLong(resultSet.getColumnIndex('familiarity'));
        const cnt = resultSet.getLong(resultSet.getColumnIndex('cnt'));
        if (fam === 0) {
          result.unlearned = cnt;
        } else if (fam === 1) {
          result.unknown = cnt;
        } else if (fam === 2) {
          result.fuzzy = cnt;
        } else if (fam >= 3) {
          result.known = cnt;
        }
      }
      resultSet.close();
      return result;
    } catch (err) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
  }

  private static rowToWord(resultSet: relationalStore.ResultSet): Word {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      word: resultSet.getString(resultSet.getColumnIndex('word')),
      meaning: resultSet.getString(resultSet.getColumnIndex('meaning')),
      familiarity: resultSet.getLong(resultSet.getColumnIndex('familiarity')),
      nextReviewTime: resultSet.getLong(resultSet.getColumnIndex('nextReviewTime')),
      usPhonetic: resultSet.getString(resultSet.getColumnIndex('usPhonetic')),
      ukPhonetic: resultSet.getString(resultSet.getColumnIndex('ukPhonetic')),
      exampleSentence: resultSet.getString(resultSet.getColumnIndex('exampleSentence'))
    };
  }
}
