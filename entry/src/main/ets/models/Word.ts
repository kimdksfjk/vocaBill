/**
 * 单词数据模型
 */
export interface Word {
  /** 单词ID（自增主键） */
  id: number;
  /** 英文单词 */
  word: string;
  /** 中文释义 */
  meaning: string;
  /** 熟悉度等级：0=未学 1=不认识 2=模糊 3=认识 */
  familiarity: number;
}
