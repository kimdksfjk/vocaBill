import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'
import { StudyStats, StudiedWordItem, FamiliarityDistData, DayStats } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'

/**
 * 统计页 - 今日/累计/周趋势/熟悉度分布
 */
@Entry
@Component
struct StatsPage {
  @State isLoading: boolean = true
  @State stats: StudyStats = {
    todayCount: 0,
    totalCount: 0,
    todayGoal: DefaultConst.DAILY_GOAL,
    correctRate: 0,
    masteredCount: 0
  }
  @State studiedWords: StudiedWordItem[] = []
  @State familiarityDist: FamiliarityDistData = { unlearned: 0, unknown: 0, fuzzy: 0, known: 0 }
  @State weeklyStats: DayStats[] = []

  aboutToAppear(): void {
    this.loadData()
  }

  async onPageShow(): Promise<void> {
    try {
      const data = await WordService.getStudyStats()
      this.stats = data
      const words = await WordService.getTodayStudiedWords()
      this.studiedWords = words
      const dist = await WordService.getFamiliarityDist()
      this.familiarityDist = dist
      const weekly = await WordService.getWeeklyStats()
      this.weeklyStats = weekly
    } catch (err) {
      // 失败时保留现有数据
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true
    const data = await WordService.getStudyStats()
    this.stats = data
    const words = await WordService.getTodayStudiedWords()
    this.studiedWords = words
    const dist = await WordService.getFamiliarityDist()
    this.familiarityDist = dist
    const weekly = await WordService.getWeeklyStats()
    this.weeklyStats = weekly
    this.isLoading = false
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingView({ tip: '加载统计...' })
      } else {
        this.MainContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
  }

  @Builder
  MainContent() {
    Column() {
      this.TopBar()

      Scroll() {
        Column() {
          // 今日概览卡片
          this.TodayOverviewCard()


          // 详细统计卡片
          this.DetailStatsCard()

          // 周趋势图
          this.WeeklyTrendSection()

          // 熟悉度分布
          this.FamiliarityDistSection()

          // 今日已学单词列表
          this.TodayWordsList()
        }
        .width('100%')
        .padding({
          left: SpacingConst.MD,
          right: SpacingConst.MD,
          bottom: SpacingConst.XXL
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  TopBar() {
    Row() {
      Text('<')
        .fontSize(FontSizeConst.HEADLINE)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .onClick(() => {
          RouterUtil.back()
        })

      Text('学习统计')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ left: SpacingConst.MD })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    .backgroundColor(ColorConst.BG_CARD)
  }

  @Builder
  TodayOverviewCard() {
    Row() {
      this.OverviewItem(`${this.stats.todayCount}`, '今日已学', ColorConst.PRIMARY)
      this.OverviewDivider()
      this.OverviewItem(`${this.stats.totalCount}`, '累计学习', ColorConst.SECONDARY)
      this.OverviewDivider()
      this.OverviewItem(`${this.stats.masteredCount}`, '已掌握', ColorConst.PRIMARY_LIGHT)
    }
    .width('100%')
    .padding({ top: SpacingConst.LG, bottom: SpacingConst.LG })
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .justifyContent(FlexAlign.SpaceEvenly)
    .margin({ top: SpacingConst.MD })
  }

  @Builder
  OverviewItem(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .margin({ top: SpacingConst.XS })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  OverviewDivider() {
    Divider()
      .vertical(true)
      .strokeWidth(1)
      .color(ColorConst.DIVIDER)
      .height(36)
  }

  @Builder
  DetailStatsCard() {
    Column() {
      Text('学习详情')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.MD })

      this.DetailRow('今日目标', `${this.stats.todayGoal} 词/天`)
      this.DetailDivider()
      this.DetailRow('今日已学', `${this.stats.todayCount} 词`)
      this.DetailDivider()
      this.DetailRow('累计学习', `${this.stats.totalCount} 词`)
      this.DetailDivider()
      this.DetailRow('已掌握', `${this.stats.masteredCount} 词`)
    }
    .width('100%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .margin({ top: SpacingConst.MD })
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)

      Blank()

      Text(value)
        .fontSize(FontSizeConst.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
    }
    .width('100%')
    .padding({ top: SpacingConst.SM, bottom: SpacingConst.SM })
  }

  @Builder
  DetailDivider() {
    Divider()
      .strokeWidth(0.5)
      .color(ColorConst.DIVIDER)
      .width('100%')
  }

  /** 周趋势图 */
  @Builder
  WeeklyTrendSection() {
    Column() {
      Text('近7天学习趋势')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.MD })

      if (this.weeklyStats.length === 0) {
        Text('暂无数据')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_HINT)
          .padding({ top: SpacingConst.SM, bottom: SpacingConst.SM })
      } else {
        Row() {
          ForEach(this.weeklyStats, (day: DayStats, index: number) => {
            this.DayBar(day, index)
          }, (day: DayStats) => day.date)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .alignItems(VerticalAlign.Bottom)
        .padding({ top: SpacingConst.MD })
      }
    }
    .width('100%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .margin({ top: SpacingConst.MD })
  }

  @Builder
  DayBar(day: DayStats, index: number) {
    Column() {
      // 柱子高度：最大 80vp
      Text(`${day.count}`)
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(day.count > 0 ? ColorConst.PRIMARY : ColorConst.TEXT_HINT)
        .margin({ bottom: SpacingConst.XS })

      // 柱体
      Column()
        .width(28)
        .height(Math.max(4, day.count > 0 ? Math.min(day.count * 4, 80) : 4))
        .backgroundColor(day.count > 0 ? ColorConst.PRIMARY : ColorConst.DIVIDER)
        .borderRadius(4)

      // 日期标签（只显示月-日）
      Text(day.date.substring(5))
        .fontSize(10)
        .fontColor(ColorConst.TEXT_HINT)
        .margin({ top: SpacingConst.XS })
    }
    .alignItems(HorizontalAlign.Center)
  }

  private getFamTotal(): number {
    return this.familiarityDist.unlearned + this.familiarityDist.unknown
      + this.familiarityDist.fuzzy + this.familiarityDist.known;
  }

  /** 熟悉度分布 */
  @Builder
  FamiliarityDistSection() {
    Column() {
      Text('熟悉度分布')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.MD })

      if (this.getFamTotal() === 0) {
        Text('暂无数据')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_HINT)
      }

      this.FamRow('未学习', this.familiarityDist.unlearned, this.getFamTotal(), ColorConst.TEXT_HINT)
      this.FamRow('不认识', this.familiarityDist.unknown, this.getFamTotal(), ColorConst.DANGER)
      this.FamRow('模糊', this.familiarityDist.fuzzy, this.getFamTotal(), ColorConst.WARNING)
      this.FamRow('已掌握', this.familiarityDist.known, this.getFamTotal(), ColorConst.PRIMARY)
    }
    .width('100%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .margin({ top: SpacingConst.MD })
  }

  @Builder
  FamRow(label: string, count: number, total: number, color: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .width(60)

        Progress({
          value: total > 0 ? count : 0,
          total: Math.max(total, 1),
          type: ProgressType.Linear
        })
          .layoutWeight(1)
          .height(8)
          .style({ strokeWidth: 8, strokeRadius: 4 })
          .color(color)
          .margin({ left: SpacingConst.SM, right: SpacingConst.SM })

        Text(`${count}`)
          .fontSize(FontSizeConst.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .width(40)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ top: SpacingConst.SM, bottom: SpacingConst.SM })
    }
    .width('100%')
  }

  @Builder
  TodayWordsList() {
    Column() {
      Text('今日已学单词')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.MD })

      if (this.studiedWords.length === 0) {
        Text('暂无学习记录')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_HINT)
          .padding({ top: SpacingConst.SM, bottom: SpacingConst.SM })
      }

      ForEach(this.studiedWords, (item: StudiedWordItem, index: number) => {
        this.WordRow(item, index)
      }, (item: StudiedWordItem) => item.id.toString())
    }
    .width('100%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .margin({ top: SpacingConst.MD })
  }

  @Builder
  WordRow(item: StudiedWordItem, index: number) {
    Column() {
      Row() {
        Text(`${index + 1}`)
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_HINT)
          .width(24)

        Text(item.word)
          .fontSize(FontSizeConst.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .layoutWeight(1)

        Text(item.meaning)
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('40%')
          .textAlign(TextAlign.End)

        Text(item.known ? '认识' : '不认识')
          .fontSize(10)
          .fontColor(item.known ? ColorConst.PRIMARY : ColorConst.DANGER)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(item.known ? ColorConst.GREEN_BG : ColorConst.RED_BG)
          .borderRadius(8)
          .margin({ left: SpacingConst.SM })
      }
      .width('100%')
      .padding({ top: SpacingConst.SM, bottom: SpacingConst.SM })

      if (index < this.studiedWords.length - 1) {
        Divider()
          .strokeWidth(0.5)
          .color(ColorConst.DIVIDER)
      }
    }
    .width('100%')
  }
}
