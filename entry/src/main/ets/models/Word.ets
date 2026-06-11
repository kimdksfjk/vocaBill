/**
 * 单词数据模型
 */
export interface Word {
  id: number
  word: string
  meaning: string
  familiarity: number
  /** 下次复习时间戳（毫秒），0 表示未调度 */
  nextReviewTime: number
  /** 美式音标 */
  usPhonetic: string
  /** 英式音标 */
  ukPhonetic: string
  /** 例句（含翻译） */
  exampleSentence: string
}

/** 待插入的新单词（不含自增id） */
export interface NewWord {
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

/**
 * 今日已学单词项（用于统计页列表展示）
 */
export interface StudiedWordItem {
  id: number
  word: string
  meaning: string
  known: boolean           // 是否认识
}

/**
 * 熟悉度分布统计
 */
export interface FamiliarityDist {
  /** 未学习 */
  unlearned: number
  /** 不认识 */
  unknown: number
  /** 模糊 */
  fuzzy: number
  /** 已掌握 */
  known: number
}

/**
 * 周趋势数据项
 */
export interface DayStats {
  /** 日期字符串 yyyy-MM-dd */
  date: string
  /** 当日学习数 */
  count: number
  /** 当日正确率 0-100 */
  correctRate: number
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
