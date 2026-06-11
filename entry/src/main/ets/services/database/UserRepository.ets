import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { User } from '../../models/User';
import { DatabaseManager } from './DatabaseManager';

const TABLE_USERS = 'users';
const TABLE_CURRENT_USER = 'current_user';

/**
 * 用户数据仓库
 */
export class UserRepository {

  /** 创建用户 */
  async createUser(username: string, passwordHash: string, createdAt: number): Promise<number> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'username': username,
        'passwordHash': passwordHash,
        'createdAt': createdAt
      };
      const rowId = await store.insert(TABLE_USERS, valueBucket);
      console.info(`[UserRepository] 用户创建成功, id: ${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[UserRepository] 创建用户失败: ${error.message}`);
      throw new Error(`创建用户失败: ${error.message}`);
    }
  }

  /** 根据用户名查找用户 */
  async findByUsername(username: string): Promise<User | null> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_USERS);
      predicates.equalTo('username', username);
      const resultSet = await store.query(predicates, ['id', 'username', 'passwordHash', 'createdAt']);
      let user: User | null = null;
      if (resultSet.goToNextRow()) {
        user = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          username: resultSet.getString(resultSet.getColumnIndex('username')),
          passwordHash: resultSet.getString(resultSet.getColumnIndex('passwordHash')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt'))
        };
      }
      resultSet.close();
      return user;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[UserRepository] 查询用户失败: ${error.message}`);
      throw new Error(`查询用户失败: ${error.message}`);
    }
  }

  /** 获取当前已登录用户的ID */
  async getLoggedInUserId(): Promise<number | null> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return null;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_CURRENT_USER);
      const resultSet = await store.query(predicates, ['id', 'userId']);
      let userId: number | null = null;
      if (resultSet.goToNextRow()) {
        userId = resultSet.getLong(resultSet.getColumnIndex('userId'));
      }
      resultSet.close();
      return userId;
    } catch (err) {
      console.error(`[UserRepository] 获取登录状态失败`);
      return null;
    }
  }

  /** 保存当前登录用户 */
  async setLoggedInUser(userId: number): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      // 先清空再插入，确保只有一条记录
      await store.executeSql('DELETE FROM current_user');
      const valueBucket: relationalStore.ValuesBucket = {
        'id': 1,
        'userId': userId
      };
      await store.insert(TABLE_CURRENT_USER, valueBucket);
      console.info(`[UserRepository] 登录会话已保存, userId: ${userId}`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[UserRepository] 保存登录会话失败: ${error.message}`);
      throw new Error(`保存登录会话失败: ${error.message}`);
    }
  }

  /** 清除登录会话 */
  async clearLoginSession(): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return;
    }
    try {
      await store.executeSql('DELETE FROM current_user');
      console.info(`[UserRepository] 登录会话已清除`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[UserRepository] 清除登录会话失败: ${error.message}`);
    }
  }

  /** 根据ID查找用户 */
  async findById(userId: number): Promise<User | null> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_USERS);
      predicates.equalTo('id', userId);
      const resultSet = await store.query(predicates, ['id', 'username', 'passwordHash', 'createdAt']);
      let user: User | null = null;
      if (resultSet.goToNextRow()) {
        user = {
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          username: resultSet.getString(resultSet.getColumnIndex('username')),
          passwordHash: resultSet.getString(resultSet.getColumnIndex('passwordHash')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt'))
        };
      }
      resultSet.close();
      return user;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[UserRepository] 查询用户失败: ${error.message}`);
      throw new Error(`查询用户失败: ${error.message}`);
    }
  }
}
