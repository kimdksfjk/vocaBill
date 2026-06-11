import { common } from '@kit.AbilityKit';
import { NewWord } from '../models/Word';
import { uint8ArrayToString } from '../utils/JsonUtil';

const CET6_FILES = ['words/CET6_1.json', 'words/CET6_2.json', 'words/CET6_3.json'];
const CET4_FILES = ['words/CET4_1.json', 'words/CET4_2.json', 'words/CET4_3.json'];

interface CetJson {
  word: string;
  us: string;
  uk: string;
  translations: CetTranslation[];
  phrases: CetPhrase[];
  sentences: CetSentence[];
}

interface CetTranslation {
  translation: string;
  type: string;
}

interface CetPhrase {
  phrase: string;
  translation: string;
}

interface CetSentence {
  sentence: string;
  translation: string;
}

/**
 * 单词播种器 — 按顺序从 CET4+6 JSON 文件中逐批加载单词
 */
export class WordSeeder {
  private static queue: NewWord[] = [];
  private static fileIndex: number = 0;
  private static allLoaded: boolean = false;

  static readonly BATCH_SIZE = 10;

  /** 所有要加载的文件列表 */
  private static get ALL_FILES(): string[] {
    return [...CET4_FILES, ...CET6_FILES];
  }

  static async loadNextBatch(context: common.Context, count: number): Promise<NewWord[]> {
    if (WordSeeder.allLoaded) {
      return [];
    }

    const allFiles = WordSeeder.ALL_FILES;
    while (WordSeeder.queue.length < count && WordSeeder.fileIndex < allFiles.length) {
      await WordSeeder.loadFile(context, allFiles[WordSeeder.fileIndex]);
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
      const words: CetJson[] = JSON.parse(jsonStr);

      for (const w of words) {
        // 构建释义：提取所有翻译
        let meaning = '';
        if (w.translations && w.translations.length > 0) {
          const parts: string[] = [];
          for (const t of w.translations) {
            parts.push(`${t.type}. ${t.translation}`);
          }
          meaning = parts.join('; ');
        }

        // 构建音标
        const usPhonetic = w.us || '';
        const ukPhonetic = w.uk || '';

        // 构建例句：取第一条例句
        let exampleSentence = '';
        if (w.sentences && w.sentences.length > 0) {
          const s = w.sentences[0];
          exampleSentence = `${s.sentence}\n${s.translation}`;
        }

        WordSeeder.queue.push({
          word: w.word,
          meaning: meaning,
          familiarity: 0,
          nextReviewTime: 0,
          usPhonetic: usPhonetic,
          ukPhonetic: ukPhonetic,
          exampleSentence: exampleSentence
        });
      }
      console.info(`[WordSeeder] 加载完成: ${fileName}, ${words.length} 个单词`);
    } catch (err) {
      console.error(`[WordSeeder] 加载失败 ${fileName}: ${JSON.stringify(err)}`);
    }
  }

  static reset(): void {
    WordSeeder.queue = [];
    WordSeeder.fileIndex = 0;
    WordSeeder.allLoaded = false;
  }

  static hasMore(): boolean {
    return !WordSeeder.allLoaded || WordSeeder.queue.length > 0;
  }
}
