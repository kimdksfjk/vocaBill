import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const DB_NAME = 'VocaBill.db';
const DB_VERSION = 1;

/** 数据库配置 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

/** 建表SQL — 单词表 */
const CREATE_TABLE_WORDS = `
  CREATE TABLE IF NOT EXISTS words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word TEXT NOT NULL,
    meaning TEXT NOT NULL,
    familiarity INTEGER DEFAULT 0
  )
`;

/** 建表SQL — 学习记录表 */
const CREATE_TABLE_REVIEW_RECORD = `
  CREATE TABLE IF NOT EXISTS review_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    wordId INTEGER NOT NULL,
    isKnown INTEGER NOT NULL,
    reviewTime INTEGER NOT NULL
  )
`;

/** 建表SQL — 用户进度表 */
const CREATE_TABLE_USER_PROGRESS = `
  CREATE TABLE IF NOT EXISTS user_progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    studiedCount INTEGER DEFAULT 0,
    targetCount INTEGER DEFAULT 20,
    accuracy REAL DEFAULT 0
  )
`;

/**
 * 数据库管理器（单例模式）
 * 负责数据库创建、初始化、建表
 */
export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  private constructor() {
  }

  /** 获取单例实例 */
  static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * 初始化数据库（必须在有Context的环境下调用）
   * @param context 应用上下文
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized && this.rdbStore) {
      return;
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.createTables();
      this.isInitialized = true;
      console.info('[DatabaseManager] 数据库初始化成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[DatabaseManager] 数据库初始化失败: ${error.code}, ${error.message}`);
      throw err;
    }
  }

  /** 创建所有表 */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    await this.rdbStore.executeSql(CREATE_TABLE_WORDS);
    await this.rdbStore.executeSql(CREATE_TABLE_REVIEW_RECORD);
    await this.rdbStore.executeSql(CREATE_TABLE_USER_PROGRESS);
    console.info('[DatabaseManager] 数据表创建完成');
  }

  /** 获取 RdbStore 实例 */
  getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  /** 关闭数据库 */
  async close(): Promise<void> {
    this.rdbStore = null;
    this.isInitialized = false;
  }
}
