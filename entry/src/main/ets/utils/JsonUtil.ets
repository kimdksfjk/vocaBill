import { util } from '@kit.ArkTS';

export function parseJson<T>(jsonStr: string): T | null {
  try {
    return JSON.parse(jsonStr) as T;
  } catch (e) {
    console.error(`[JsonUtil] JSON 解析失败: ${e}`);
    return null;
  }
}

export function toJson(obj: object): string {
  try {
    return JSON.stringify(obj);
  } catch (e) {
    console.error(`[JsonUtil] JSON 序列化失败: ${e}`);
    return '';
  }
}

export function uint8ArrayToString(data: Uint8Array): string {
  const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  return textDecoder.decodeToString(data, { stream: false });
}

export function stringToUint8Array(str: string): Uint8Array {
  const textEncoder = new util.TextEncoder();
  return textEncoder.encodeInto(str);
}
