import { Word, StudyStats, StudyRecord } from '../models/Word'

/**
 * 数据服务接口桩 - 由成员B实现具体逻辑
 * 当前提供模拟数据供UI开发调试
 */
export class WordService {
  // ========== 模拟数据 ==========
  private static mockWords: Word[] = [
    { id: 1, word: 'abandon', meaning: 'v. 放弃；抛弃', familiarity: 0 },
    { id: 2, word: 'brilliant', meaning: 'adj. 杰出的；明亮的', familiarity: 0 },
    { id: 3, word: 'curious', meaning: 'adj. 好奇的；奇特的', familiarity: 0 },
    { id: 4, word: 'demonstrate', meaning: 'v. 证明；演示', familiarity: 0 },
    { id: 5, word: 'enthusiasm', meaning: 'n. 热情；热心', familiarity: 0 },
    { id: 6, word: 'flexible', meaning: 'adj. 灵活的；易弯曲的', familiarity: 0 },
    { id: 7, word: 'generous', meaning: 'adj. 慷慨的；大方的', familiarity: 0 },
    { id: 8, word: 'hesitate', meaning: 'v. 犹豫；迟疑', familiarity: 0 },
    { id: 9, word: 'illustrate', meaning: 'v. 阐明；举例说明', familiarity: 0 },
    { id: 10, word: 'journey', meaning: 'n. 旅程；旅行', familiarity: 0 },
  ]

  private static mockStats: StudyStats = {
    todayCount: 5,
    totalCount: 42,
    todayGoal: 20,
    correctRate: 85,
    masteredCount: 30
  }

  // ========== 单词相关接口 ==========

  /** 获取今日待学习单词列表 */
  static getTodayWords(): Promise<Word[]> {
    return Promise.resolve(WordService.mockWords)
  }

  /** 获取单词详情 */
  static getWordDetail(wordId: number): Promise<Word | undefined> {
    const word = WordService.mockWords.find((w: Word) => w.id === wordId)
    return Promise.resolve(word)
  }

  // ========== 学习记录接口 ==========

  /** 记录学习结果 */
  static recordResult(wordId: number, known: boolean): Promise<boolean> {
    return Promise.resolve(true)
  }

  /** 批量记录学习结果 */
  static recordBatchResults(records: StudyRecord[]): Promise<boolean> {
    return Promise.resolve(true)
  }

  // ========== 统计相关接口 ==========

  /** 获取学习统计数据 */
  static getStudyStats(): Promise<StudyStats> {
    return Promise.resolve(WordService.mockStats)
  }

  // ========== 设置相关接口 ==========

  /** 获取每日目标 */
  static getDailyGoal(): Promise<number> {
    return Promise.resolve(20)
  }

  /** 设置每日目标 */
  static setDailyGoal(goal: number): Promise<boolean> {
    return Promise.resolve(true)
  }

  /** 重置所有学习数据 */
  static resetAllData(): Promise<boolean> {
    return Promise.resolve(true)
  }
}
