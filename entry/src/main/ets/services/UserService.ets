import { User, AuthResult } from '../models/User';
import { UserRepository } from './database/UserRepository';
import { CryptoUtil } from '../utils/CryptoUtil';

/**
 * 用户服务 — 处理注册/登录/登出业务逻辑
 * 所有方法均为 static，参照 WordService 的调用模式
 */
export class UserService {
  private static userRepo: UserRepository = new UserRepository();

  /**
   * 注册新用户
   * @param username 用户名
   * @param password 密码
   * @returns 操作结果
   */
  static async register(username: string, password: string): Promise<AuthResult> {
    // 校验用户名
    if (!username || username.trim().length === 0) {
      return { success: false, message: '用户名不能为空' };
    }
    if (username.trim().length < 2) {
      return { success: false, message: '用户名至少2个字符' };
    }
    if (username.trim().length > 20) {
      return { success: false, message: '用户名不能超过20个字符' };
    }

    // 校验密码
    if (!password || password.length === 0) {
      return { success: false, message: '密码不能为空' };
    }
    if (password.length < 6) {
      return { success: false, message: '密码至少6个字符' };
    }

    const trimmedUsername = username.trim();

    try {
      // 检查用户名是否已存在
      const existingUser = await UserService.userRepo.findByUsername(trimmedUsername);
      if (existingUser !== null) {
        return { success: false, message: '用户名已存在' };
      }

      // 哈希密码
      const passwordHash = await CryptoUtil.hashPassword(password);

      // 创建用户
      const userId = await UserService.userRepo.createUser(trimmedUsername, passwordHash, Date.now());

      // 自动登录
      await UserService.userRepo.setLoggedInUser(userId);

      const user: User = {
        id: userId,
        username: trimmedUsername,
        passwordHash: passwordHash,
        createdAt: Date.now()
      };

      return { success: true, message: '注册成功', user: user };
    } catch (err) {
      console.error(`[UserService] 注册失败: ${JSON.stringify(err)}`);
      return { success: false, message: '注册失败，请稍后重试' };
    }
  }

  /**
   * 用户登录
   * @param username 用户名
   * @param password 密码
   * @returns 操作结果
   */
  static async login(username: string, password: string): Promise<AuthResult> {
    if (!username || username.trim().length === 0) {
      return { success: false, message: '请输入用户名' };
    }
    if (!password || password.length === 0) {
      return { success: false, message: '请输入密码' };
    }

    const trimmedUsername = username.trim();

    try {
      const user = await UserService.userRepo.findByUsername(trimmedUsername);
      if (user === null) {
        return { success: false, message: '用户名或密码错误' };
      }

      const passwordValid = await CryptoUtil.verifyPassword(password, user.passwordHash);
      if (!passwordValid) {
        return { success: false, message: '用户名或密码错误' };
      }

      // 保存登录会话
      await UserService.userRepo.setLoggedInUser(user.id);

      return { success: true, message: '登录成功', user: user };
    } catch (err) {
      console.error(`[UserService] 登录失败: ${JSON.stringify(err)}`);
      return { success: false, message: '登录失败，请稍后重试' };
    }
  }

  /**
   * 退出登录
   */
  static async logout(): Promise<void> {
    try {
      await UserService.userRepo.clearLoginSession();
    } catch (err) {
      console.error(`[UserService] 退出登录失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 获取当前登录用户
   * @returns 用户对象或 null
   */
  static async getCurrentUser(): Promise<User | null> {
    try {
      const userId = await UserService.userRepo.getLoggedInUserId();
      if (userId === null) {
        return null;
      }
      return await UserService.userRepo.findById(userId);
    } catch (err) {
      console.error(`[UserService] 获取当前用户失败: ${JSON.stringify(err)}`);
      return null;
    }
  }

  /**
   * 检查是否已登录
   * @returns 是否已登录
   */
  static async isLoggedIn(): Promise<boolean> {
    try {
      const userId = await UserService.userRepo.getLoggedInUserId();
      return userId !== null;
    } catch (err) {
      return false;
    }
  }
}
