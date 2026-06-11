import { User, AuthResult } from '../models/User';
import { UserRepository } from './database/UserRepository';
import { CryptoUtil } from '../utils/CryptoUtil';

export class UserService {
  private static userRepo: UserRepository = new UserRepository();

  static async register(username: string, password: string): Promise<AuthResult> {
    if (!username || username.trim().length === 0) {
      return { success: false, message: '用户名不能为空' };
    }
    if (username.trim().length < 2) {
      return { success: false, message: '用户名至少2个字符' };
    }
    if (username.trim().length > 20) {
      return { success: false, message: '用户名不能超过20个字符' };
    }
    if (!password || password.length === 0) {
      return { success: false, message: '密码不能为空' };
    }
    if (password.length < 6) {
      return { success: false, message: '密码至少6个字符' };
    }

    const trimmedUsername = username.trim();
    try {
      const existingUser = await UserService.userRepo.findByUsername(trimmedUsername);
      if (existingUser !== null) {
        return { success: false, message: '用户名已存在' };
      }
      const passwordHash = await CryptoUtil.hashPassword(password);
      const userId = await UserService.userRepo.createUser(trimmedUsername, passwordHash, Date.now());
      await UserService.userRepo.setLoggedInUser(userId);
      const user: User = { id: userId, username: trimmedUsername, passwordHash: passwordHash, createdAt: Date.now() };
      return { success: true, message: '注册成功', user: user };
    } catch (err) {
      return { success: false, message: '注册失败，请稍后重试' };
    }
  }

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
      await UserService.userRepo.setLoggedInUser(user.id);
      return { success: true, message: '登录成功', user: user };
    } catch (err) {
      return { success: false, message: '登录失败，请稍后重试' };
    }
  }

  static async logout(): Promise<void> {
    try {
      await UserService.userRepo.clearLoginSession();
    } catch (err) {
      // ignore
    }
  }

  static async getCurrentUserId(): Promise<number | null> {
    try {
      return await UserService.userRepo.getLoggedInUserId();
    } catch (err) {
      return null;
    }
  }

  static async getCurrentUser(): Promise<User | null> {
    try {
      const userId = await UserService.userRepo.getLoggedInUserId();
      if (userId === null) return null;
      return await UserService.userRepo.findById(userId);
    } catch (err) {
      return null;
    }
  }

  static async isLoggedIn(): Promise<boolean> {
    try {
      const userId = await UserService.userRepo.getLoggedInUserId();
      return userId !== null;
    } catch (err) {
      return false;
    }
  }
}
