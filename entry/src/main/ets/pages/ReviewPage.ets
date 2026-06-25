import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { WordWithState, StudyRecord } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'
import { WordCard } from '../components/WordCard'
import { ReviewButtons } from '../components/ReviewButtons'
import { ProgressBar } from '../components/ProgressBar'
import promptAction from '@ohos.promptAction'

/**
 * 核心复习页 - 显示当前单词、复习按钮、跳过功能
 */
@Entry
@Component
struct ReviewPage {
  @StorageLink('ReviewSession_WordList') wordList: WordWithState[] = []
  @StorageLink('ReviewSession_CurrentIndex') currentIndex: number = 0
  @StorageLink('ReviewSession_KnownRecords') knownRecords: StudyRecord[] = []
  
  @State isLoading: boolean = true
  @State showMeaning: boolean = false
  @State isFinished: boolean = false
  @State isEmpty: boolean = false
  @State correctCount: number = 0
  @State skippedCount: number = 0
  @State currentWord: WordWithState = {
    id: 0,
    word: '',
    meaning: '',
    familiarity: 0,
    nextReviewTime: 0,
    usPhonetic: '',
    ukPhonetic: '',
    exampleSentence: ''
  }
  private nextTimerId: number = -1

  aboutToAppear(): void {
    if (this.wordList && this.wordList.length > 0 && this.currentIndex < this.wordList.length) {
      this.currentWord = this.wordList[this.currentIndex]
      this.isLoading = false
    } else {
      this.loadWords()
    }
  }

  aboutToDisappear(): void {
    this.clearNextTimer()
    this.saveResults() // Save intermediate progress when leaving
  }

  private clearNextTimer(): void {
    if (this.nextTimerId !== -1) {
      clearTimeout(this.nextTimerId)
      this.nextTimerId = -1
    }
  }

  private loadWords(): void {
    this.isLoading = true
    WordService.preloadFullBank().then(() => {
      return WordService.getTodayWords()
    }).then((words: WordWithState[]) => {
      this.wordList = words
      if (words.length > 0) {
        this.currentWord = words[0]
        this.currentIndex = 0
      } else {
        this.isEmpty = true
      }
      this.isLoading = false
    }).catch((err: Error) => {
      console.error(`[ReviewPage] 加载单词失败: ${JSON.stringify(err)}`)
      this.isEmpty = true
      this.isLoading = false
    })
  }

  private onToggleMeaning(): void {
    this.showMeaning = true
  }

  private onKnown(): void {
    this.knownRecords.push({
      wordId: this.currentWord.id,
      known: true,
      timestamp: Date.now(),
      mode: 'Casual'
    })
    this.correctCount++
    this.nextWord()
  }

  private onUnknown(): void {
    this.knownRecords.push({
      wordId: this.currentWord.id,
      known: false,
      timestamp: Date.now(),
      mode: 'Casual'
    })
    this.nextWord()
  }

  /** 跳过当前单词（不记录结果，放到列表末尾） */
  private onSkip(): void {
    if (this.wordList.length <= 1) {
      // 只有一个词，跳过等同于完成
      this.isFinished = true
      return
    }
    // 将当前单词移到列表末尾
    const currentWord = this.wordList[this.currentIndex]
    this.wordList.splice(this.currentIndex, 1)
    this.wordList.push(currentWord)
    this.skippedCount++
    // 显示寓意重置
    this.showMeaning = false
    // 切换到下一个（索引不变，因为当前项被移除了）
    this.currentWord = this.wordList[this.currentIndex]
    promptAction.showToast({ message: '已跳过，稍后再学', duration: 1200 })
  }

  private nextWord(): void {
    this.clearNextTimer()
    const nextIndex = this.currentIndex + 1

    if (nextIndex >= this.wordList.length) {
      this.isFinished = true
      return
    }

    this.nextTimerId = setTimeout(() => {
      this.currentIndex = nextIndex
      this.currentWord = this.wordList[nextIndex]
      this.showMeaning = false
    }, DefaultConst.AUTO_NEXT_DELAY)
  }

  private async saveResults(): Promise<void> {
    if (this.knownRecords.length > 0) {
      await WordService.recordBatchResults(this.knownRecords)
      this.knownRecords = []
    }
  }

  private async refreshSession(): Promise<void> {
    this.wordList = []
    this.currentIndex = 0
    this.knownRecords = []
    this.isFinished = false
    this.isEmpty = false
    await this.loadWords()
  }

  private async goHome(): Promise<void> {
    await this.saveResults()
    if (this.isFinished) {
      this.wordList = []
      this.currentIndex = 0
    }
    RouterUtil.replace(RouteConst.HOME)
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingView({ tip: '正在准备单词...' })
      } else if (this.isEmpty) {
        this.EmptyView()
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

  @Builder
  ReviewContent() {
    Column() {
      this.TopBar()

      ProgressBar({
        current: this.currentIndex,
        total: this.wordList.length,
        showText: true
      })
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
        .margin({ top: SpacingConst.SM })

      // 复习标签（区分新词和复习词）
      if (this.currentWord.nextReviewTime > 0) {
        Text('🔄 复习')
          .fontSize(12)
          .fontColor(ColorConst.WARNING)
          .padding({ top: SpacingConst.XS, bottom: SpacingConst.XS, left: SpacingConst.SM, right: SpacingConst.SM })
          .backgroundColor('#FFF8E1')
          .borderRadius(8)
          .margin({ top: SpacingConst.SM })
      } else {
        Text('🆕 新词')
          .fontSize(12)
          .fontColor(ColorConst.SECONDARY)
          .padding({ top: SpacingConst.XS, bottom: SpacingConst.XS, left: SpacingConst.SM, right: SpacingConst.SM })
          .backgroundColor('#E3F2FD')
          .borderRadius(8)
          .margin({ top: SpacingConst.SM })
      }

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

      if (this.showMeaning) {
        Text('这个单词你认识吗？')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_HINT)
          .textAlign(TextAlign.Center)
          .margin({ bottom: SpacingConst.SM })
      }

      ReviewButtons({
        showMeaning: this.showMeaning,
        onKnown: (): void => {
          this.onKnown()
        },
        onUnknown: (): void => {
          this.onUnknown()
        }
      })
        .margin({ bottom: SpacingConst.SM })

      // 跳过按钮
      if (this.showMeaning) {
        Button() {
          Text('跳过 →')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        .backgroundColor(Color.Transparent)
        .height(40)
        .onClick(() => {
          this.onSkip()
        })
        .margin({ bottom: SpacingConst.LG })
      }
    }
    .width('100%')
  }

  @Builder
  TopBar() {
    Row() {
      Text('✕')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .onClick(() => {
          this.goHome()
        })

      Blank()

      Text(`第 ${this.currentIndex + 1}/${this.wordList.length} 词`)
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)

      Blank()

      Text('换一组')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.PRIMARY)
        .onClick(() => {
          this.refreshSession()
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    .backgroundColor(ColorConst.BG_CARD)
  }

  @Builder
  FinishedView() {
    Column() {
      Column() {
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

        Row() {
          this.FinishStatItem('认识', this.correctCount, ColorConst.SECONDARY)
          this.FinishStatDivider()
          this.FinishStatItem('不认识', this.wordList.length - this.correctCount - this.skippedCount, ColorConst.DANGER)
          this.FinishStatDivider()
          this.FinishStatItem('跳过', this.skippedCount, ColorConst.WARNING)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: SpacingConst.LG })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

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

  @Builder
  EmptyView() {
    Column() {
      Text('今日学习已完成')
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.SM })

      Text('所有单词都已学过，明天再来吧')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)

      Button('返回首页')
        .fontSize(FontSizeConst.BODY)
        .fontColor(Color.White)
        .backgroundColor(ColorConst.PRIMARY)
        .borderRadius(RadiusConst.XL)
        .height(48)
        .padding({ left: SpacingConst.XXL, right: SpacingConst.XXL })
        .margin({ top: SpacingConst.XXL })
        .onClick(() => {
          RouterUtil.replace(RouteConst.HOME)
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
