/**
 * 用户数据模型
 */
export interface User {
  /** 用户ID（自增主键） */
  id: number;
  /** 用户名（唯一） */
  username: string;
  /** 密码哈希值 */
  passwordHash: string;
  /** 创建时间戳（毫秒） */
  createdAt: number;
}

/**
 * 登录会话记录
 */
export interface LoginSession {
  /** 记录ID */
  id: number;
  /** 当前登录用户ID */
  userId: number;
}

/**
 * 注册/登录操作结果
 */
export interface AuthResult {
  /** 是否成功 */
  success: boolean;
  /** 提示信息 */
  message: string;
  /** 成功后返回的用户对象 */
  user?: User;
}
