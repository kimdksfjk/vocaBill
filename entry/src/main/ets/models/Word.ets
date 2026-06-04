/**
 * 单词数据模型 - 由成员B定义
 */
export interface Word {
  id: number
  word: string
  meaning: string
  familiarity: number
}

/**
 * 学习统计模型
 */
export interface StudyStats {
  todayCount: number       // 今日已学
  totalCount: number       // 累计学习
  todayGoal: number        // 今日目标
  correctRate: number      // 正确率 0-100
  masteredCount: number    // 已掌握单词数
}

/**
 * 学习记录模型
 */
export interface StudyRecord {
  wordId: number
  known: boolean           // 是否认识
  timestamp: number
}
