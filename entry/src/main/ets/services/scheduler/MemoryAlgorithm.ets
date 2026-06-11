/**
 * 记忆算法 — 艾宾浩斯遗忘曲线
 * 复习间隔（天）：1, 2, 4, 7, 15, 30
 *
 * 熟悉度等级：
 *   0 = 未学习
 *   1 = 不认识
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

export function getIntervalDays(familiarity: number): number {
  if (familiarity <= 0 || familiarity > EBBINGHAUS_INTERVALS.length) {
    return EBBINGHAUS_INTERVALS[0];
  }
  return EBBINGHAUS_INTERVALS[familiarity - 1];
}

export function getNextReviewTime(familiarity: number, fromTime?: number): number {
  const base = fromTime ?? Date.now();
  const intervalDays = getIntervalDays(familiarity);
  return base + intervalDays * DAY_MS;
}

export function onKnown(currentFamiliarity: number): number {
  if (currentFamiliarity < 3) {
    return currentFamiliarity + 1;
  }
  return 3;
}

export function onUnknown(): number {
  return 1;
}

export function isDueForReview(lastReviewTime: number, familiarity: number): boolean {
  const nextTime = getNextReviewTime(familiarity, lastReviewTime);
  return Date.now() >= nextTime;
}
