import { common } from '@kit.AbilityKit';
import { Word } from '../models/Word';
import { uint8ArrayToString } from '../utils/JsonUtil';

const CET6_FILES = ['words/CET6_1.json', 'words/CET6_2.json', 'words/CET6_3.json'];

interface Cet6WordJson {
  word: string;
  translations: Cet6Translation[];
}

interface Cet6Translation {
  translation: string;
  type: string;
}

/**
 * 单词播种器 — 按顺序从 CET6 JSON 文件中逐批加载单词
 * 每次调用 loadNextBatch() 最多返回 BATCH_SIZE 个单词，
 * 内部按文件顺序缓存并推进位置，用完一个文件后自动加载下一个。
 */
export class WordSeeder {
  private static queue: Word[] = [];
  private static fileIndex: number = 0;
  private static allLoaded: boolean = false;

  static readonly BATCH_SIZE = 10;

  /**
   * 获取下一批单词（最多 count 个）
   * 内存队列不足时自动从下一个 JSON 文件加载
   */
  static async loadNextBatch(context: common.Context, count: number): Promise<Word[]> {
    if (WordSeeder.allLoaded) {
      return [];
    }

    while (WordSeeder.queue.length < count && WordSeeder.fileIndex < CET6_FILES.length) {
      await WordSeeder.loadFile(context, CET6_FILES[WordSeeder.fileIndex]);
      WordSeeder.fileIndex++;
    }

    if (WordSeeder.queue.length === 0) {
      WordSeeder.allLoaded = true;
      return [];
    }

    const batch = WordSeeder.queue.splice(0, Math.min(count, WordSeeder.queue.length));
    return batch;
  }

  private static async loadFile(context: common.Context, fileName: string): Promise<void> {
    try {
      const rawData: Uint8Array = await context.resourceManager.getRawFileContent(fileName);
      const jsonStr = uint8ArrayToString(rawData);
      const cet6Words: Cet6WordJson[] = JSON.parse(jsonStr);

      for (const w of cet6Words) {
        let meaning = '';
        if (w.translations && w.translations.length > 0) {
          meaning = `${w.translations[0].type}. ${w.translations[0].translation}`;
        }
        WordSeeder.queue.push({
          id: 0,      // 占位；DB 批量插入后自增
          word: w.word,
          meaning: meaning,
          familiarity: 0
        });
      }
      console.info(`[WordSeeder] 加载完成: ${fileName}, ${cet6Words.length} 个单词`);
    } catch (err) {
      console.error(`[WordSeeder] 加载失败 ${fileName}: ${JSON.stringify(err)}`);
    }
  }

  /** 重置状态（清空所有数据时调用） */
  static reset(): void {
    WordSeeder.queue = [];
    WordSeeder.fileIndex = 0;
    WordSeeder.allLoaded = false;
  }

  /** 是否还有单词可加载 */
  static hasMore(): boolean {
    return !WordSeeder.allLoaded || WordSeeder.queue.length > 0;
  }
}
