/**
 * 记忆算法 — 艾宾浩斯遗忘曲线
 * 复习间隔（天）：1, 2, 4, 7, 15, 30
 *
 * 熟悉度等级：
 *   0 = 未学习
 *   1 = 不认识（每次点击"不认识"后重置为1）
 *   2 = 模糊
 *   3 = 认识
 *
 * 当用户点击"认识"时，熟悉度 +1（最高到3）
 * 当用户点击"不认识"时，熟悉度重置为1
 */

/** 艾宾浩斯复习间隔（天） */
const EBBINGHAUS_INTERVALS: number[] = [1, 2, 4, 7, 15, 30];

/** 一天毫秒数 */
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * 计算当前熟悉度对应的下次复习间隔（天）
 * @param familiarity 当前熟悉度（0-3）
 * @returns 间隔天数
 */
export function getIntervalDays(familiarity: number): number {
  if (familiarity <= 0 || familiarity > EBBINGHAUS_INTERVALS.length) {
    // 未学习或首次学习，第二天就复习
    return EBBINGHAUS_INTERVALS[0];
  }
  return EBBINGHAUS_INTERVALS[familiarity - 1];
}

/**
 * 计算下次复习时间戳
 * @param familiarity 学习后的熟悉度
 * @param fromTime 基准时间戳（毫秒），默认当前时间
 * @returns 下次复习时间戳（毫秒）
 */
export function getNextReviewTime(familiarity: number, fromTime?: number): number {
  const base = fromTime ?? Date.now();
  const intervalDays = getIntervalDays(familiarity);
  return base + intervalDays * DAY_MS;
}

/**
 * 计算用户回答"认识"后的新熟悉度
 * @param currentFamiliarity 当前熟悉度
 * @returns 新熟悉度
 */
export function onKnown(currentFamiliarity: number): number {
  if (currentFamiliarity < 3) {
    return currentFamiliarity + 1;
  }
  return 3;
}

/**
 * 计算用户回答"不认识"后的新熟悉度
 * @returns 重置后的熟悉度（1）
 */
export function onUnknown(): number {
  return 1;
}

/**
 * 判断某个单词是否到了复习时间
 * @param lastReviewTime 上次复习时间戳（毫秒）
 * @param familiarity 复习后的熟悉度
 * @returns 是否需要复习
 */
export function isDueForReview(lastReviewTime: number, familiarity: number): boolean {
  const nextTime = getNextReviewTime(familiarity, lastReviewTime);
  return Date.now() >= nextTime;
}
