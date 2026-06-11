import { common } from '@kit.AbilityKit';
import { NewWord } from '../models/Word';
import { uint8ArrayToString } from '../utils/JsonUtil';

const CET4_FILES = ['words/CET4_1.json', 'words/CET4_2.json', 'words/CET4_3.json'];
const CET6_FILES = ['words/CET6_1.json', 'words/CET6_2.json', 'words/CET6_3.json'];

/** 词库类型 */
export type WordBank = 'cet4' | 'cet6' | 'cet4_cet6';

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
 * 单词播种器
 * 核心原则：
 * - loadAllWords() 一次性加载全部词库到内存
 * - 调用方负责将这批数据写入 DB
 * - 切换词库时只需重新调用即可
 */
export class WordSeeder {

  /** 一次性加载指定词库的全部单词 */
  static async loadAllWords(context: common.Context, bank: WordBank): Promise<NewWord[]> {
    const files = WordSeeder.getFiles(bank);
    const all: NewWord[] = [];

    for (const file of files) {
      try {
        const rawData: Uint8Array = await context.resourceManager.getRawFileContent(file);
        const jsonStr = uint8ArrayToString(rawData);
        const words: CetJson[] = JSON.parse(jsonStr);

        for (const w of words) {
          let meaning = '';
          if (w.translations && w.translations.length > 0) {
            const parts: string[] = [];
            for (const t of w.translations) {
              parts.push(`${t.type}. ${t.translation}`);
            }
            meaning = parts.join('; ');
          }

          all.push({
            word: w.word,
            meaning: meaning,
            familiarity: 0,
            nextReviewTime: 0,
            usPhonetic: w.us || '',
            ukPhonetic: w.uk || '',
            exampleSentence: WordSeeder.buildExample(w)
          });
        }
        console.info(`[WordSeeder] 加载完成: ${file}, ${words.length} 个单词`);
      } catch (err) {
        console.error(`[WordSeeder] 加载失败 ${file}: ${JSON.stringify(err)}`);
      }
    }

    console.info(`[WordSeeder] 加载完成: 共 ${all.length} 个单词 (bank: ${bank})`);
    return all;
  }

  private static getFiles(bank: WordBank): string[] {
    switch (bank) {
      case 'cet4':
        return [...CET4_FILES];
      case 'cet6':
        return [...CET6_FILES];
      case 'cet4_cet6':
      default:
        return [...CET4_FILES, ...CET6_FILES];
    }
  }

  private static buildExample(w: CetJson): string {
    if (w.sentences && w.sentences.length > 0) {
      const s = w.sentences[0];
      return `${s.sentence}\n${s.translation}`;
    }
    return '';
  }
}
