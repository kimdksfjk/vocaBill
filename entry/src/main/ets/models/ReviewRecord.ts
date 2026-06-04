/**
 * 学习记录数据模型
 */
export interface ReviewRecord {
  /** 记录ID（自增主键） */
  id: number;
  /** 关联的单词ID */
  wordId: number;
  /** 是否认识（true=认识, false=不认识） */
  isKnown: boolean;
  /** 复习时间戳（毫秒） */
  reviewTime: number;
}
