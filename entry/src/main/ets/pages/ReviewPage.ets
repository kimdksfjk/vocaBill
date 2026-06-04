import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'
import { Word, StudyRecord } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'
import { WordCard } from '../components/WordCard'
import { ReviewButtons } from '../components/ReviewButtons'
import { ProgressBar } from '../components/ProgressBar'

/**
 * 核心复习页 - 显示当前单词、点击显示释义、认识/不认识按钮、自动切换下一词、进度显示
 */
@Entry
@Component
struct ReviewPage {
  @State isLoading: boolean = true
  @State wordList: Word[] = []
  @State currentIndex: number = 0
  @State showMeaning: boolean = false
  @State isFinished: boolean = false
  @State correctCount: number = 0
  @State currentWord: Word = {
    id: 0,
    word: '',
    meaning: '',
    familiarity: 0
  }
  @State knownRecords: StudyRecord[] = []

  aboutToAppear(): void {
    this.loadWords()
  }

  private loadWords(): void {
    this.isLoading = true
    WordService.getTodayWords().then((words: Word[]) => {
      this.wordList = words
      if (words.length > 0) {
        this.currentWord = words[0]
        this.currentIndex = 0
      }
      this.isLoading = false
    }).catch(() => {
      this.isLoading = false
    })
  }

  /** 点击显示释义 */
  private onToggleMeaning(): void {
    this.showMeaning = true
  }

  /** 认识 */
  private onKnown(): void {
    this.knownRecords.push({
      wordId: this.currentWord.id,
      known: true,
      timestamp: Date.now()
    })
    this.correctCount++
    this.nextWord()
  }

  /** 不认识 */
  private onUnknown(): void {
    this.knownRecords.push({
      wordId: this.currentWord.id,
      known: false,
      timestamp: Date.now()
    })
    this.nextWord()
  }

  /** 切换到下一个单词 */
  private nextWord(): void {
    const nextIndex = this.currentIndex + 1

    if (nextIndex >= this.wordList.length) {
      // 全部学完
      this.isFinished = true
      this.saveResults()
      return
    }

    // 自动切换到下一个单词（带延迟，让用户看到反馈）
    setTimeout(() => {
      this.currentIndex = nextIndex
      this.currentWord = this.wordList[nextIndex]
      this.showMeaning = false
    }, DefaultConst.AUTO_NEXT_DELAY)
  }

  /** 保存学习结果 */
  private saveResults(): void {
    if (this.knownRecords.length > 0) {
      WordService.recordBatchResults(this.knownRecords)
    }
  }

  /** 返回首页 */
  private goHome(): void {
    RouterUtil.back()
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingView({ tip: '正在准备单词...' })
      } else if (this.isFinished) {
        this.FinishedView()
      } else {
        this.ReviewContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
  }

  /** 复习中内容 */
  @Builder
  ReviewContent() {
    Column() {
      // 顶部栏
      this.TopBar()

      // 进度条
      ProgressBar({
        current: this.currentIndex,
        total: this.wordList.length,
        showText: true
      })
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
        .margin({ top: SpacingConst.SM })

      // 单词卡片（居中占据主要空间）
      Column() {
        WordCard({
          word: this.currentWord,
          showMeaning: $showMeaning,
          cardIndex: this.currentIndex,
          onToggleMeaning: (): void => {
            this.onToggleMeaning()
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 提示文字
      if (this.showMeaning) {
        Text('这个单词你认识吗？')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_HINT)
          .textAlign(TextAlign.Center)
          .margin({ bottom: SpacingConst.MD })
      }

      // 复习按钮
      ReviewButtons({
        showMeaning: this.showMeaning,
        onKnown: (): void => {
          this.onKnown()
        },
        onUnknown: (): void => {
          this.onUnknown()
        }
      })
        .margin({ bottom: SpacingConst.XXL })
    }
    .width('100%')
  }

  /** 顶部栏 */
  @Builder
  TopBar() {
    Row() {
      Text('✕')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .onClick(() => {
          this.saveResults()
          RouterUtil.back()
        })

      Blank()

      Text(`第 ${this.currentIndex + 1}/${this.wordList.length} 词`)
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)

      Blank()

      // 占位保持居中
      Text('✕')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(Color.Transparent)
    }
    .width('100%')
    .height(48)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    .backgroundColor(ColorConst.BG_CARD)
  }

  /** 完成页面 */
  @Builder
  FinishedView() {
    Column() {
      Column() {
        // 完成图标
        Text('🎉')
          .fontSize(64)

        Text('学习完成！')
          .fontSize(FontSizeConst.HEADLINE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .margin({ top: SpacingConst.MD })

        Text(`本次学习 ${this.wordList.length} 个单词`)
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.SM })

        // 统计小结
        Row() {
          this.FinishStatItem('认识', this.correctCount, ColorConst.SECONDARY)
          this.FinishStatDivider()
          this.FinishStatItem('不认识', this.wordList.length - this.correctCount, ColorConst.DANGER)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: SpacingConst.LG })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 返回按钮
      Button('返回首页')
        .width('80%')
        .height(52)
        .fontSize(FontSizeConst.TITLE)
        .fontColor(Color.White)
        .backgroundColor(ColorConst.PRIMARY)
        .borderRadius(RadiusConst.XL)
        .margin({ bottom: SpacingConst.XXL })
        .onClick(() => {
          this.goHome()
        })
    }
    .width('100%')
  }

  @Builder
  FinishStatItem(label: string, count: number, color: string) {
    Column() {
      Text(`${count}`)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FinishStatDivider() {
    Divider()
      .vertical(true)
      .strokeWidth(1)
      .color(ColorConst.DIVIDER)
      .height(40)
  }
}
