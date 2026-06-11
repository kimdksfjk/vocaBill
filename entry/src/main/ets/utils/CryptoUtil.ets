import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

/** 固定 salt，增加密码破解难度 */
const SALT = 'VocaBill@2024!Salt#Key';

/**
 * 密码哈希工具类
 * 使用 SHA-256 + 固定 salt 对密码进行哈希
 */
export class CryptoUtil {

  /**
   * 对密码进行 SHA-256 哈希
   * @param password 明文密码
   * @returns 十六进制哈希字符串
   */
  static async hashPassword(password: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256');
      const saltedPassword = password + SALT;
      const textEncoder = util.TextEncoder.create();
      const encoded = textEncoder.encodeInto(saltedPassword);
      const input: cryptoFramework.DataBlob = {
        data: new Uint8Array(encoded)
      };
      await md.update(input);
      const result = await md.digest();
      return CryptoUtil.toHexString(result.data);
    } catch (err) {
      console.error(`[CryptoUtil] 密码哈希失败: ${JSON.stringify(err)}`);
      throw new Error('密码哈希失败');
    }
  }

  /**
   * 验证密码是否匹配
   * @param password 明文密码
   * @param hash 存储的哈希值
   * @returns 是否匹配
   */
  static async verifyPassword(password: string, hash: string): Promise<boolean> {
    const computedHash = await CryptoUtil.hashPassword(password);
    return computedHash === hash;
  }

  /**
   * Uint8Array 转十六进制字符串
   */
  private static toHexString(data: Uint8Array): string {
    let hex = '';
    for (let i = 0; i < data.length; i++) {
      const byteHex = (data[i] & 0xFF).toString(16);
      hex += byteHex.length === 1 ? '0' + byteHex : byteHex;
    }
    return hex;
  }
}
