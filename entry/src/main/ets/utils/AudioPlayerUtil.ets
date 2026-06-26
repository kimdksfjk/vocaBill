import media from '@ohos.multimedia.media';

export class AudioPlayerUtil {
  private static avPlayer: media.AVPlayer | null = null;
  private static isPlaying: boolean = false;

  static async playWord(word: string, pref: string = 'british'): Promise<void> {
    if (!word) {
      return;
    }
    // 防止重复点击并发播放导致状态机错乱
    if (AudioPlayerUtil.isPlaying && AudioPlayerUtil.avPlayer) {
      AudioPlayerUtil.avPlayer.release();
      AudioPlayerUtil.isPlaying = false;
    }

    try {
      AudioPlayerUtil.isPlaying = true;
      let avPlayer = await media.createAVPlayer();
      AudioPlayerUtil.avPlayer = avPlayer;
      
      avPlayer.on('stateChange', async (state, reason) => {
        switch (state) {
          case 'initialized':
            avPlayer.prepare();
            break;
          case 'prepared':
            avPlayer.play();
            break;
          case 'completed':
            avPlayer.release();
            AudioPlayerUtil.avPlayer = null;
            AudioPlayerUtil.isPlaying = false;
            break;
          case 'error':
            console.error('AudioPlayerUtil state error:', reason);
            avPlayer.release();
            AudioPlayerUtil.avPlayer = null;
            AudioPlayerUtil.isPlaying = false;
            break;
        }
      });
      
      const typeStr = pref === 'american' ? '2' : '1';
      avPlayer.url = `https://dict.youdao.com/dictvoice?audio=${encodeURIComponent(word)}&type=${typeStr}`;

    } catch (error) {
      console.error(`AudioPlayerUtil 播放发音失败: ${error}`);
      AudioPlayerUtil.isPlaying = false;
    }
  }
}
