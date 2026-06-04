import { util } from '@kit.ArkTS';

/**
 * JSON 工具类
 * 提供 JSON 解析等常用方法
 */

/**
 * 安全解析 JSON 字符串
 * @param jsonStr JSON 字符串
 * @returns 解析后的对象，解析失败返回 null
 */
export function parseJson<T>(jsonStr: string): T | null {
  try {
    return JSON.parse(jsonStr) as T;
  } catch (e) {
    console.error(`[JsonUtil] JSON 解析失败: ${e}`);
    return null;
  }
}

/**
 * 安全将对象序列化为 JSON 字符串
 * @param obj 要序列化的对象
 * @returns JSON 字符串
 */
export function toJson(obj: object): string {
  try {
    return JSON.stringify(obj);
  } catch (e) {
    console.error(`[JsonUtil] JSON 序列化失败: ${e}`);
    return '';
  }
}

/**
 * 将 Uint8Array 转换为字符串
 * @param data 二进制数据
 */
export function uint8ArrayToString(data: Uint8Array): string {
  const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  return textDecoder.decodeToString(data, { stream: false });
}

/**
 * 将字符串转换为 Uint8Array
 * @param str 字符串
 */
export function stringToUint8Array(str: string): Uint8Array {
  const textEncoder = new util.TextEncoder();
  return textEncoder.encodeInto(str);
}
