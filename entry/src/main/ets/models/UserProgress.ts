/**
 * 用户学习进度数据模型
 */
export interface UserProgress {
  /** 记录ID（自增主键） */
  id: number;
  /** 日期字符串，格式 yyyy-MM-dd */
  date: string;
  /** 今日已学习单词数 */
  studiedCount: number;
  /** 今日目标单词数 */
  targetCount: number;
  /** 今日正确率（0-1） */
  accuracy: number;
}
