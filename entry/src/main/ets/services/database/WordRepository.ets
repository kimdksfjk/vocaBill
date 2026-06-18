import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Word, NewWord, WordWithState, FamiliarityDistData } from '../../models/Word';
import { DatabaseManager } from './DatabaseManager';

const TABLE_WORDS = 'words';
const TABLE_USER_WORD_STATE = 'user_word_state';

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
      valueBuckets.push({
        'word': w.word,
        'meaning': w.meaning,
        'usPhonetic': w.usPhonetic,
        'ukPhonetic': w.ukPhonetic,
        'exampleSentence': w.exampleSentence
      });
    }
    try {
      const count = await store.batchInsert(TABLE_WORDS, valueBuckets);
      return count;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`批量插入失败: ${error.message}`);
    }
  }

  /** 查询所有词条 + 指定用户的学习状态 */
  async getAllWordsWithState(userId: number): Promise<WordWithState[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const sql = `
        SELECT w.id, w.word, w.meaning, w.usPhonetic, w.ukPhonetic, w.exampleSentence,
               COALESCE(s.familiarity, 0) AS familiarity,
               COALESCE(s.nextReviewTime, 0) AS nextReviewTime
        FROM words w
        LEFT JOIN user_word_state s ON w.id = s.wordId AND s.userId = ?
        ORDER BY w.id ASC
      `;
      const resultSet = await store.querySql(sql, [userId.toString()]);
      const words: WordWithState[] = [];
      while (resultSet.goToNextRow()) {
        words.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          word: resultSet.getString(resultSet.getColumnIndex('word')),
          meaning: resultSet.getString(resultSet.getColumnIndex('meaning')),
          usPhonetic: resultSet.getString(resultSet.getColumnIndex('usPhonetic')),
          ukPhonetic: resultSet.getString(resultSet.getColumnIndex('ukPhonetic')),
          exampleSentence: resultSet.getString(resultSet.getColumnIndex('exampleSentence')),
          familiarity: resultSet.getLong(resultSet.getColumnIndex('familiarity')),
          nextReviewTime: resultSet.getLong(resultSet.getColumnIndex('nextReviewTime'))
        });
      }
      resultSet.close();
      return words;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`查询单词失败: ${error.message}`);
    }
  }

  async getWordById(wordId: number): Promise<Word | null> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_WORDS);
      predicates.equalTo('id', wordId);
      const resultSet = await store.query(predicates,
        ['id', 'word', 'meaning', 'usPhonetic', 'ukPhonetic', 'exampleSentence']);
      let word: Word | null = null;
      if (resultSet.goToNextRow()) {
        word = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          word: resultSet.getString(resultSet.getColumnIndex('word')),
          meaning: resultSet.getString(resultSet.getColumnIndex('meaning')),
          usPhonetic: resultSet.getString(resultSet.getColumnIndex('usPhonetic')),
          ukPhonetic: resultSet.getString(resultSet.getColumnIndex('ukPhonetic')),
          exampleSentence: resultSet.getString(resultSet.getColumnIndex('exampleSentence'))
        };
      }
      resultSet.close();
      return word;
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`查询单词失败: ${error.message}`);
    }
  }

  /** 更新或插入用户对某词的学习状态 */
  async upsertWordState(userId: number, wordId: number, familiarity: number, nextReviewTime: number): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      // 先尝试更新
      const predicates = new relationalStore.RdbPredicates(TABLE_USER_WORD_STATE);
      predicates.equalTo('userId', userId);
      predicates.equalTo('wordId', wordId);
      const valueBucket: relationalStore.ValuesBucket = {
        'familiarity': familiarity,
        'nextReviewTime': nextReviewTime
      };
      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        // 没有记录则插入
        await store.insert(TABLE_USER_WORD_STATE, {
          'userId': userId,
          'wordId': wordId,
          'familiarity': familiarity,
          'nextReviewTime': nextReviewTime
        });
      }
    } catch (err) {
      const error = err as BusinessError;
      throw new Error(`更新词状态失败: ${error.message}`);
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
      throw new Error(`获取单词总数失败: ${error.message}`);
    }
  }

  /** 某用户的已学单词数 */
  async getStudiedWordCount(userId: number): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return 0;
    }
    try {
      const sql = 'SELECT COUNT(DISTINCT wordId) AS cnt FROM review_record WHERE userId = ?';
      const resultSet = await store.querySql(sql, [userId.toString()]);
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

  /** 某用户的熟悉度分布 */
  async getFamiliarityDist(userId: number): Promise<FamiliarityDistData> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
    try {
      // 已学习过的词 → 从 user_word_state 统计
      const sql = `SELECT familiarity, COUNT(*) AS cnt FROM ${TABLE_USER_WORD_STATE}
                   WHERE userId = ? AND familiarity > 0
                   GROUP BY familiarity`;
      const resultSet = await store.querySql(sql, [userId.toString()]);
      let unknown = 0, fuzzy = 0, known = 0;
      while (resultSet.goToNextRow()) {
        const fam = resultSet.getLong(resultSet.getColumnIndex('familiarity'));
        const cnt = resultSet.getLong(resultSet.getColumnIndex('cnt'));
        if (fam === 1) unknown = cnt;
        else if (fam === 2) fuzzy = cnt;
        else if (fam >= 3) known = cnt;
      }
      resultSet.close();
      // 未学习 = 总词数 - 已学习词数
      const totalCount = await this.getWordCount();
      const unlearned = totalCount - unknown - fuzzy - known;
      return { unlearned: Math.max(0, unlearned), unknown, fuzzy, known };
    } catch (err) {
      return { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 };
    }
  }

  /** 获取与指定词性匹配的随机释义 */
  async getRandomMeaningsByPos(pos: string, excludeWordId: number, limitCount: number): Promise<string[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return [];
    }
    try {
      const sql = `SELECT meaning FROM ${TABLE_WORDS} WHERE meaning LIKE ? AND id != ? ORDER BY RANDOM() LIMIT ?`;
      const resultSet = await store.querySql(sql, [pos + '%', excludeWordId.toString(), limitCount.toString()]);
      const meanings: string[] = [];
      while (resultSet.goToNextRow()) {
        meanings.push(resultSet.getString(resultSet.getColumnIndex('meaning')));
      }
      resultSet.close();
      return meanings;
    } catch (err) {
      return [];
    }
  }

  /** 获取任意随机释义（用于同词性不足时的兜底） */
  async getRandomMeanings(excludeWordId: number, limitCount: number): Promise<string[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return [];
    }
    try {
      const sql = `SELECT meaning FROM ${TABLE_WORDS} WHERE id != ? ORDER BY RANDOM() LIMIT ?`;
      const resultSet = await store.querySql(sql, [excludeWordId.toString(), limitCount.toString()]);
      const meanings: string[] = [];
      while (resultSet.goToNextRow()) {
        meanings.push(resultSet.getString(resultSet.getColumnIndex('meaning')));
      }
      resultSet.close();
      return meanings;
    } catch (err) {
      return [];
    }
  }
}
