import { ColorConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'
import { WordWithState } from '../models/Word'
import { AudioPlayerUtil } from '../utils/AudioPlayerUtil'
import { WordService } from '../services/WordService'
import promptAction from '@ohos.promptAction'

/**
 * 单词卡片组件 - 显示单词与释义
 * 点击卡片可切换显示/隐藏释义
 */
@Component
export struct WordCard {
  @Prop word: WordWithState = {
    id: 0, word: '', meaning: '', familiarity: 0,
    nextReviewTime: 0, usPhonetic: '', ukPhonetic: '', exampleSentence: ''
  }
  @Link showMeaning: boolean
  @Prop cardIndex: number = 0        // 当前卡片索引
  @State pronunciationPref: string = 'british'
  onToggleMeaning?: () => void

  aboutToAppear() {
    WordService.getPronunciationPref().then((pref) => {
      this.pronunciationPref = pref;
    });
  }

  build() {
    Column() {
      // 卡片序号
      Text(`${this.cardIndex + 1}`)
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_HINT)
        .margin({ bottom: SpacingConst.MD })

      // 单词
      Text(this.word.word)
        .fontSize(FontSizeConst.WORD)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .margin({ bottom: SpacingConst.SM })

      // 音标（优先显示用户偏好的音标）和发音喇叭
      Row() {
        if (this.word.usPhonetic || this.word.ukPhonetic) {
          Text(`/${this.word.ukPhonetic || this.word.usPhonetic}/`)
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        Text('🔊')
          .fontSize(FontSizeConst.TITLE)
          .margin({ left: SpacingConst.MD })
          .stateStyles({
            pressed: {
              .opacity(0.5)
            },
            normal: {
              .opacity(1.0)
            }
          })
          .onClick(() => {
            promptAction.showToast({ 
              message: this.pronunciationPref === 'american' ? '🗣️ 播放美式发音' : '🗣️ 播放英式发音', 
              duration: 1000 
            })
            AudioPlayerUtil.playWord(this.word.word, this.pronunciationPref)
          })
      }
      .margin({ bottom: SpacingConst.MD })
      .justifyContent(FlexAlign.Center)

      // 分隔线
      if (!this.showMeaning) {
        Divider()
          .strokeWidth(1)
          .color(ColorConst.DIVIDER)
          .width('60%')
      }

      // 释义区域（点击后显示）
      if (this.showMeaning) {
        Column() {
          Divider()
            .strokeWidth(1)
            .color(ColorConst.DIVIDER)
            .width('60%')
            .margin({ bottom: SpacingConst.LG })

          Text(this.word.meaning)
            .fontSize(FontSizeConst.HEADLINE)
            .fontColor(ColorConst.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .lineHeight(32)
            .transition(
              TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut })
                .combine(TransitionEffect.translate({ y: 20 }).animation({ duration: 300 }))
            )

          // 例句
          if (this.word.exampleSentence) {
            Divider()
              .strokeWidth(0.5)
              .color(ColorConst.DIVIDER)
              .width('80%')
              .margin({ top: SpacingConst.LG, bottom: SpacingConst.LG })

            Text(this.word.exampleSentence)
              .fontSize(FontSizeConst.CAPTION)
              .fontColor(ColorConst.TEXT_HINT)
              .textAlign(TextAlign.Center)
              .lineHeight(20)
              .transition(
                TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.EaseInOut })
              )
          }
        }
      }

      // 提示文字
      if (!this.showMeaning) {
        Text('点击卡片显示释义')
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_HINT)
          .margin({ top: SpacingConst.LG })
      }
    }
    .width('88%')
    .padding({
      top: SpacingConst.XXL,
      bottom: SpacingConst.XXL,
      left: SpacingConst.LG,
      right: SpacingConst.LG
    })
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetY: 4
    })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (!this.showMeaning && this.onToggleMeaning) {
        this.onToggleMeaning()
      }
    })
  }
}
