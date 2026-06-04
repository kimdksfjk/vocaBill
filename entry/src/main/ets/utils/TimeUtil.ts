/**
 * 时间工具类
 * 提供时间格式化等常用方法
 */

/** 一天毫秒数 */
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * 格式化时间戳为 yyyy-MM-dd 字符串
 * @param timestamp 时间戳（毫秒）
 */
export function formatDate(timestamp: number): string {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * 格式化时间戳为 yyyy-MM-dd HH:mm:ss 字符串
 * @param timestamp 时间戳（毫秒）
 */
export function formatDateTime(timestamp: number): string {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

/**
 * 获取今日起始时间戳（当天00:00:00的毫秒数）
 */
export function getTodayStart(): number {
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  return now.getTime();
}

/**
 * 获取指定日期字符串对应的起始时间戳
 * @param dateStr 日期字符串 yyyy-MM-dd
 */
export function getDateStart(dateStr: string): number {
  const date = new Date(dateStr);
  return date.getTime();
}
