import { common } from '@kit.AbilityKit';
import { NewWord } from '../models/Word';
import { uint8ArrayToString } from '../utils/JsonUtil';

const CET4_FILES = ['words/CET4_1.json', 'words/CET4_2.json', 'words/CET4_3.json'];
const CET6_FILES = ['words/CET6_1.json', 'words/CET6_2.json', 'words/CET6_3.json'];

export type WordBank = 'cet4' | 'cet6' | 'cet4_cet6';

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

interface CetJson {
  word: string;
  us: string;
  uk: string;
  translations: CetTranslation[];
  phrases: CetPhrase[];
  sentences: CetSentence[];
}

export class WordSeeder {

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

          const exampleSentence = w.sentences && w.sentences.length > 0
            ? `${w.sentences[0].sentence}\n${w.sentences[0].translation}` : '';

          all.push({
            word: w.word,
            meaning: meaning,
            usPhonetic: w.us || '',
            ukPhonetic: w.uk || '',
            exampleSentence: exampleSentence
          });
        }
      } catch (err) {
        console.error(`[WordSeeder] 加载失败 ${file}: ${JSON.stringify(err)}`);
      }
    }

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
}
