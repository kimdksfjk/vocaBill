/**
 * 单词数据模型（仅词条元数据，不含用户学习状态）
 */
export interface Word {
  id: number
  word: string
  meaning: string
  usPhonetic: string
  ukPhonetic: string
  exampleSentence: string
}

/** 待插入的新单词（不含自增id） */
export interface NewWord {
  word: string
  meaning: string
  usPhonetic: string
  ukPhonetic: string
  exampleSentence: string
}

/** 单词 + 该用户的复习状态（合并查询结果） */
export interface WordWithState {
  id: number
  word: string
  meaning: string
  familiarity: number
  nextReviewTime: number
  usPhonetic: string
  ukPhonetic: string
  exampleSentence: string
}

/**
 * 学习统计模型
 */
export interface StudyStats {
  todayCount: number
  totalCount: number
  todayGoal: number
  correctRate: number
  masteredCount: number
}

/**
 * 学习记录模型
 */
export interface StudyRecord {
  wordId: number
  known: boolean
  timestamp: number
}

/**
 * 今日已学单词项
 */
export interface StudiedWordItem {
  id: number
  word: string
  meaning: string
  known: boolean
}

/**
 * 熟悉度分布数据
 */
export interface FamiliarityDistData {
  unlearned: number
  unknown: number
  fuzzy: number
  known: number
}

/**
 * 周趋势数据项
 */
export interface DayStats {
  date: string
  count: number
  correctRate: number
}
