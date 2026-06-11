import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const DB_NAME = 'VocaBill.db';

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
    date TEXT NOT NULL UNIQUE,
    studiedCount INTEGER DEFAULT 0,
    targetCount INTEGER DEFAULT 20,
    accuracy INTEGER DEFAULT 0
  )
`;

/**
 * 数据库管理器（单例模式）
 * 负责数据库创建、初始化、建表
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private appContext: common.Context | null = null;

  private constructor() {
  }

  static getInstance(): DatabaseManager {
    if (DatabaseManager.instance === null) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.isInitialized && this.rdbStore !== null) {
      return;
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      this.appContext = context;
      await this.createTables();
      this.isInitialized = true;
      console.info('[DatabaseManager] 数据库初始化成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[DatabaseManager] 数据库初始化失败: ${error.code}, ${error.message}`);
      throw new Error(`数据库初始化失败: ${error.message}`);
    }
  }

  private async createTables(): Promise<void> {
    if (this.rdbStore === null) {
      return;
    }
    await this.rdbStore.executeSql(CREATE_TABLE_WORDS);
    await this.rdbStore.executeSql(CREATE_TABLE_REVIEW_RECORD);
    await this.rdbStore.executeSql(CREATE_TABLE_USER_PROGRESS);
    console.info('[DatabaseManager] 数据表创建完成');
  }

  getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  getContext(): common.Context | null {
    return this.appContext;
  }

  async close(): Promise<void> {
    this.rdbStore = null;
    this.appContext = null;
    this.isInitialized = false;
  }
}
