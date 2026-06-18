import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { WordWithState, StudyRecord } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'
import { ProgressBar } from '../components/ProgressBar'
import promptAction from '@ohos.promptAction'

@Entry
@Component
export struct DeepLearningPage {
  @StorageLink('DeepSession_WordList') wordList: WordWithState[] = []
  @StorageLink('DeepSession_CurrentIndex') currentIndex: number = 0
  @StorageLink('DeepSession_Phase') phase: number = 1
  @StorageLink('DeepSession_Phase1Queue') phase1Queue: number[] = []
  @StorageLink('DeepSession_Options') options: string[] = []
  @StorageLink('DeepSession_KnownRecords') knownRecords: StudyRecord[] = []
  @StorageLink('DeepSession_CorrectCount') correctCount: number = 0
  
  @State isLoading: boolean = true
  @State selectedOptionIndex: number = -1
  @State isCorrectOption: boolean = false
  @State isFinished: boolean = false
  @State isEmpty: boolean = false
  @State skippedCount: number = 0
  
  @State currentWord: WordWithState = {
    id: 0, word: '', meaning: '', familiarity: 0, nextReviewTime: 0,
    usPhonetic: '', ukPhonetic: '', exampleSentence: ''
  }

  aboutToAppear(): void {
    if (this.wordList && this.wordList.length > 0) {
      if (this.phase === 1 && this.phase1Queue.length > 0) {
        this.currentIndex = this.phase1Queue[0]
      }
      this.currentWord = this.wordList[this.currentIndex]
      this.isLoading = false
      if (this.phase === 1 && this.options.length === 0) {
        this.prepareOptions()
      }
    } else {
      this.loadWords()
    }
  }

  aboutToDisappear(): void {
    this.saveResults() // Save intermediate progress
  }

  private async loadWords(): Promise<void> {
    this.isLoading = true
    try {
      await WordService.preloadFullBank()
      const words = await WordService.getTodayWords()
      this.wordList = words
      if (words.length > 0) {
        const queue: number[] = []
        for (let i = 0; i < words.length; i++) {
          queue.push(i)
        }
        this.phase1Queue = queue
        this.currentIndex = this.phase1Queue[0]
        this.currentWord = words[this.currentIndex]
        this.phase = 1
        this.correctCount = 0
        this.knownRecords = []
        await this.prepareOptions()
      } else {
        this.isEmpty = true
      }
    } catch (err) {
      console.error(`[DeepLearningPage] 加载失败: ${JSON.stringify(err)}`)
      this.isEmpty = true
    }
    this.isLoading = false
  }

  private async prepareOptions(): Promise<void> {
    this.selectedOptionIndex = -1
    this.options = await WordService.generateOptionsForWord(this.currentWord)
  }

  private onOptionSelected(index: number, option: string): void {
    if (this.selectedOptionIndex !== -1) return // Already selected
    this.selectedOptionIndex = index
    this.isCorrectOption = (option === this.currentWord.meaning)
    
    // We delay before going to the next word
    setTimeout(async () => {
      if (this.isCorrectOption) {
        this.phase1Queue.shift() // 正确，移除当前词
      } else {
        const failedIndex = this.phase1Queue.shift()
        if (failedIndex !== undefined) {
          this.phase1Queue.push(failedIndex) // 错误，移到队尾再复习
        }
      }
      await this.nextWordPhase1()
    }, 1000)
  }

  private async nextWordPhase1(): Promise<void> {
    if (this.phase1Queue.length === 0) {
      // Phase 1 finished, go to Phase 2
      this.phase = 2
      this.currentIndex = 0
      this.currentWord = this.wordList[0]
      promptAction.showToast({ message: '第一轮结束，进入第二轮回忆测试', duration: 2000 })
    } else {
      this.currentIndex = this.phase1Queue[0]
      this.currentWord = this.wordList[this.currentIndex]
      await this.prepareOptions()
    }
  }

  private async nextWordPhase2(known: boolean): Promise<void> {
    this.knownRecords.push({
      wordId: this.currentWord.id,
      known: known,
      timestamp: Date.now()
    })
    if (known) {
      this.correctCount++
    }
    
    const nextIndex = this.currentIndex + 1
    if (nextIndex >= this.wordList.length) {
      this.isFinished = true
    } else {
      this.currentIndex = nextIndex
      this.currentWord = this.wordList[nextIndex]
    }
  }

  private async saveResults(): Promise<void> {
    if (this.knownRecords.length > 0) {
      await WordService.recordBatchResults(this.knownRecords)
      this.knownRecords = []
    }
  }

  private async goHome(): Promise<void> {
    await this.saveResults()
    if (this.isFinished) {
      this.wordList = []
      this.currentIndex = 0
      this.phase1Queue = []
      this.options = []
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
        if (this.phase === 1) {
          this.Phase1Content()
        } else {
          this.Phase2Content()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
  }

  @Builder
  TopBar(title: string) {
    Row() {
      Text('✕')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .onClick(() => {
          this.goHome()
        })
      Blank()
      Text(title)
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
      Blank()
      Text('✕')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(Color.Transparent)
    }
    .width('100%')
    .height(48)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    .backgroundColor(ColorConst.BG_CARD)
  }

  @Builder
  Phase1Content() {
    Column() {
      this.TopBar(`第一轮：已答对 ${this.wordList.length - this.phase1Queue.length}/${this.wordList.length} 词`)
      ProgressBar({ current: this.wordList.length - this.phase1Queue.length, total: this.wordList.length, showText: true })
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
        .margin({ top: SpacingConst.SM })

      // Word display
      Column() {
        Text(this.currentWord.word)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConst.TEXT_PRIMARY)
        
        Row() {
          if (this.currentWord.ukPhonetic) {
            Text(`英 /${this.currentWord.ukPhonetic}/`)
              .fontSize(FontSizeConst.BODY)
              .fontColor(ColorConst.TEXT_SECONDARY)
              .margin({ right: SpacingConst.MD })
          }
          if (this.currentWord.usPhonetic) {
            Text(`美 /${this.currentWord.usPhonetic}/`)
              .fontSize(FontSizeConst.BODY)
              .fontColor(ColorConst.TEXT_SECONDARY)
          }
        }
        .margin({ top: SpacingConst.MD })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // Options
      Column() {
        ForEach(this.options, (item: string, index: number) => {
          this.OptionButton(item, index)
        })
      }
      .width('100%')
      .padding(SpacingConst.LG)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  OptionButton(option: string, index: number) {
    Button() {
      Text(option)
        .fontSize(FontSizeConst.BODY)
        .fontColor(
          this.selectedOptionIndex === -1 ? ColorConst.TEXT_PRIMARY : 
          (option === this.currentWord.meaning ? Color.White : 
            (this.selectedOptionIndex === index ? Color.White : ColorConst.TEXT_PRIMARY))
        )
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(SpacingConst.MD)
    .margin({ bottom: SpacingConst.SM })
    .backgroundColor(
      this.selectedOptionIndex === -1 ? ColorConst.BG_CARD : 
      (option === this.currentWord.meaning ? ColorConst.SECONDARY : 
        (this.selectedOptionIndex === index ? ColorConst.DANGER : ColorConst.BG_CARD))
    )
    .borderRadius(RadiusConst.MD)
    .border({ width: 1, color: ColorConst.DIVIDER })
    .onClick(() => {
      this.onOptionSelected(index, option)
    })
  }

  @Builder
  Phase2Content() {
    Column() {
      this.TopBar(`第二轮：第 ${this.currentIndex + 1}/${this.wordList.length} 词`)
      ProgressBar({ current: this.currentIndex, total: this.wordList.length, showText: true })
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
        .margin({ top: SpacingConst.SM })

      Column() {
        Text('这个词义对应的单词你认识吗？')
          .fontSize(FontSizeConst.TITLE)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .margin({ bottom: SpacingConst.XL })
        
        Text(this.currentWord.meaning)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConst.PRIMARY)
          .textAlign(TextAlign.Center)
          .padding(SpacingConst.MD)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      Row() {
        Button('不认识')
          .width('40%')
          .height(52)
          .backgroundColor(ColorConst.DANGER)
          .fontColor(Color.White)
          .fontSize(FontSizeConst.TITLE)
          .borderRadius(RadiusConst.LG)
          .onClick(() => { this.nextWordPhase2(false) })
        
        Button('认识')
          .width('40%')
          .height(52)
          .backgroundColor(ColorConst.SECONDARY)
          .fontColor(Color.White)
          .fontSize(FontSizeConst.TITLE)
          .borderRadius(RadiusConst.LG)
          .onClick(() => { this.nextWordPhase2(true) })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: SpacingConst.XXL })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FinishedView() {
    Column() {
      Column() {
        Text('🎉').fontSize(64)
        Text('深度学习完成！')
          .fontSize(FontSizeConst.HEADLINE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .margin({ top: SpacingConst.MD })
        Text(`本次学习 ${this.wordList.length} 个单词`)
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.SM })
          
        Row() {
          Column() {
            Text(`${this.correctCount}`).fontSize(36).fontWeight(FontWeight.Bold).fontColor(ColorConst.SECONDARY)
            Text('认识').fontSize(FontSizeConst.CAPTION).fontColor(ColorConst.TEXT_SECONDARY)
          }
          Divider().vertical(true).height(40).color(ColorConst.DIVIDER)
          Column() {
            Text(`${this.wordList.length - this.correctCount}`).fontSize(36).fontWeight(FontWeight.Bold).fontColor(ColorConst.DANGER)
            Text('不认识').fontSize(FontSizeConst.CAPTION).fontColor(ColorConst.TEXT_SECONDARY)
          }
        }
        .width('60%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: SpacingConst.LG })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      Button('返回首页')
        .width('80%')
        .height(52)
        .fontSize(FontSizeConst.TITLE)
        .fontColor(Color.White)
        .backgroundColor(ColorConst.PRIMARY)
        .borderRadius(RadiusConst.XL)
        .margin({ bottom: SpacingConst.XXL })
        .onClick(() => { this.goHome() })
    }
    .width('100%')
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
        .onClick(() => { RouterUtil.replace(RouteConst.HOME) })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
