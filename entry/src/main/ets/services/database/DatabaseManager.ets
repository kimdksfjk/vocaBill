import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const DB_NAME = 'VocaBill.db';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

/** 当前数据库 schema 版本 */
const DB_VERSION = 2;

/** 建表SQL — 单词表（v2：含音标、例句、复习时间） */
const CREATE_TABLE_WORDS = `
  CREATE TABLE IF NOT EXISTS words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word TEXT NOT NULL,
    meaning TEXT NOT NULL,
    familiarity INTEGER DEFAULT 0,
    nextReviewTime INTEGER DEFAULT 0,
    usPhonetic TEXT DEFAULT '',
    ukPhonetic TEXT DEFAULT '',
    exampleSentence TEXT DEFAULT ''
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
    accuracy REAL DEFAULT 0
  )
`;

/** 建表SQL — 用户账户表 */
const CREATE_TABLE_USERS = `
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    passwordHash TEXT NOT NULL,
    createdAt INTEGER NOT NULL
  )
`;

/** 建表SQL — 当前登录用户表 */
const CREATE_TABLE_CURRENT_USER = `
  CREATE TABLE IF NOT EXISTS current_user (
    id INTEGER PRIMARY KEY,
    userId INTEGER NOT NULL
  )
`;

/** 建表SQL — 用户设置表 */
const CREATE_TABLE_SETTINGS = `
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
`;

/** schema 版本管理表 */
const CREATE_TABLE_SCHEMA = `
  CREATE TABLE IF NOT EXISTS schema_version (
    id INTEGER PRIMARY KEY,
    version INTEGER NOT NULL
  )
`;

/**
 * 数据库管理器（单例）
 * 负责数据库创建、初始化、schema 迁移
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private appContext: common.Context | null = null;

  private constructor() {}

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

      // schema 迁移
      const oldVersion = await this.getSchemaVersion();
      if (oldVersion < DB_VERSION) {
        await this.migrate(oldVersion);
        await this.setSchemaVersion(DB_VERSION);
      }

      // 确保所有表存在
      await this.ensureTables();
      this.isInitialized = true;
      console.info('[DatabaseManager] 数据库初始化成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[DatabaseManager] 数据库初始化失败: ${error.code}, ${error.message}`);
      throw new Error(`数据库初始化失败: ${error.message}`);
    }
  }

  /** 迁移逻辑：旧版本表结构不兼容则重建 */
  private async migrate(oldVersion: number): Promise<void> {
    if (this.rdbStore === null) {
      return;
    }
    console.info(`[DatabaseManager] schema 迁移: v${oldVersion} → v${DB_VERSION}`);
    // v1 → v2：words 表新增了 nextReviewTime / usPhonetic / ukPhonetic / exampleSentence 列
    // 新增了 settings、users、current_user、schema_version 表
    // 最安全的方式：删除旧 words/review_record/user_progress 表，后续由 seeder 重新填充
    if (oldVersion < 2) {
      try {
        await this.rdbStore.executeSql('DROP TABLE IF EXISTS words');
        await this.rdbStore.executeSql('DROP TABLE IF EXISTS review_record');
        await this.rdbStore.executeSql('DROP TABLE IF EXISTS user_progress');
        console.info('[DatabaseManager] 已清理 v1 旧表，将重新创建');
      } catch (err) {
        const error = err as BusinessError;
        console.warn(`[DatabaseManager] 清理旧表失败: ${error.message}`);
      }
    }
  }

  /** 确保所有基础表存在 */
  private async ensureTables(): Promise<void> {
    if (this.rdbStore === null) {
      return;
    }
    await this.rdbStore.executeSql(CREATE_TABLE_WORDS);
    await this.rdbStore.executeSql(CREATE_TABLE_REVIEW_RECORD);
    await this.rdbStore.executeSql(CREATE_TABLE_USER_PROGRESS);
    await this.rdbStore.executeSql(CREATE_TABLE_USERS);
    await this.rdbStore.executeSql(CREATE_TABLE_CURRENT_USER);
    await this.rdbStore.executeSql(CREATE_TABLE_SETTINGS);
    await this.rdbStore.executeSql(CREATE_TABLE_SCHEMA);
    console.info('[DatabaseManager] 数据表创建完成');
  }

  private async getSchemaVersion(): Promise<number> {
    if (this.rdbStore === null) {
      return 0;
    }
    try {
      const resultSet = await this.rdbStore.querySql('SELECT version FROM schema_version WHERE id = 1');
      let version = 0;
      if (resultSet.goToNextRow()) {
        version = resultSet.getLong(resultSet.getColumnIndex('version'));
      }
      resultSet.close();
      return version;
    } catch (_err) {
      // schema_version 表可能还不存在
      return 0;
    }
  }

  private async setSchemaVersion(version: number): Promise<void> {
    if (this.rdbStore === null) {
      return;
    }
    try {
      // upsert
      await this.rdbStore.executeSql('DELETE FROM schema_version');
      const bucket: relationalStore.ValuesBucket = { 'id': 1, 'version': version };
      await this.rdbStore.insert('schema_version', bucket);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[DatabaseManager] 写入 schema 版本失败: ${error.message}`);
    }
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
