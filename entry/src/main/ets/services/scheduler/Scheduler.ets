import { onKnown, onUnknown, getNextReviewTime } from './MemoryAlgorithm';

/** 复习调度结果 */
export class ScheduleResult {
  newFamiliarity: number;
  nextReviewTime: number;

  constructor(newFamiliarity: number, nextReviewTime: number) {
    this.newFamiliarity = newFamiliarity;
    this.nextReviewTime = nextReviewTime;
  }
}

/**
 * 调度器 — 管理单词复习调度逻辑
 */
export class Scheduler {

  handleKnown(currentFamiliarity: number): ScheduleResult {
    const newFamiliarity: number = onKnown(currentFamiliarity);
    const nextReviewTime: number = getNextReviewTime(newFamiliarity);
    return new ScheduleResult(newFamiliarity, nextReviewTime);
  }

  handleUnknown(): ScheduleResult {
    const newFamiliarity: number = onUnknown();
    const nextReviewTime: number = getNextReviewTime(newFamiliarity);
    return new ScheduleResult(newFamiliarity, nextReviewTime);
  }
}
