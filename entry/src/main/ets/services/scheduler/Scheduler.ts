import { onKnown, onUnknown, getNextReviewTime } from './MemoryAlgorithm';

/**
 * 调度器 — 管理单词复习调度逻辑
 * 结合 MemoryAlgorithm 为成员A提供统一的调用接口
 */
export class Scheduler {

  /**
   * 用户点击"认识"
   * @param currentFamiliarity 当前熟悉度
   * @returns { newFamiliarity: 新熟悉度, nextReviewTime: 下次复习时间戳 }
   */
  handleKnown(currentFamiliarity: number):
    { newFamiliarity: number; nextReviewTime: number } {
    const newFamiliarity = onKnown(currentFamiliarity);
    const nextReviewTime = getNextReviewTime(newFamiliarity);
    return { newFamiliarity, nextReviewTime };
  }

  /**
   * 用户点击"不认识"
   * @returns { newFamiliarity: 新熟悉度（1）, nextReviewTime: 下次复习时间戳 }
   */
  handleUnknown():
    { newFamiliarity: number; nextReviewTime: number } {
    const newFamiliarity = onUnknown();
    const nextReviewTime = getNextReviewTime(newFamiliarity);
    return { newFamiliarity, nextReviewTime };
  }
}
