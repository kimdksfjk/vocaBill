import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';

const TABLE_SETTINGS = 'settings';

/**
 * 设置数据仓库 — 键值对存储
 * 用于存储学习提醒、发音偏好等简单设置
 */
export class SettingsRepository {

  /** 获取设置值 */
  async get(key: string, defaultValue: string = ''): Promise<string> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return defaultValue;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_SETTINGS);
      predicates.equalTo('key', key);
      const resultSet = await store.query(predicates, ['value']);
      let value = defaultValue;
      if (resultSet.goToNextRow()) {
        value = resultSet.getString(resultSet.getColumnIndex('value'));
      }
      resultSet.close();
      return value;
    } catch (err) {
      return defaultValue;
    }
  }

  /** 获取布尔设置值 */
  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    const val = await this.get(key, defaultValue ? 'true' : 'false');
    return val === 'true';
  }

  /** 设置值 */
  async set(key: string, value: string): Promise<boolean> {
    const store = DatabaseManager.getInstance().getStore();
    if (store === null) {
      return false;
    }
    try {
      // upsert: 先尝试 update，行数为 0 时 insert
      const predicates = new relationalStore.RdbPredicates(TABLE_SETTINGS);
      predicates.equalTo('key', key);
      const valueBucket: relationalStore.ValuesBucket = { 'value': value };
      const rows = await store.update(valueBucket, predicates);
      if (rows === 0) {
        const insertBucket: relationalStore.ValuesBucket = {
          'key': key,
          'value': value
        };
        await store.insert(TABLE_SETTINGS, insertBucket);
      }
      return true;
    } catch (err) {
      console.error(`[SettingsRepository] 设置失败: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /** 设置布尔值 */
  async setBoolean(key: string, value: boolean): Promise<boolean> {
    return await this.set(key, value ? 'true' : 'false');
  }
}
