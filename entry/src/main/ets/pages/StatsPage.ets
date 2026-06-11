import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'
import { StudyStats } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'

/**
 * 统计页 - 今日/累计学习量、正确率
 * UI由A开发，数据由B提供
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

  aboutToAppear(): void {
    this.loadData()
  }

  onPageShow(): void {
    this.reloadStats()
  }

  private async reloadStats(): Promise<void> {
    const data = await WordService.getStudyStats()
    this.stats = data
  }

  private async loadData(): Promise<void> {
    this.isLoading = true
    const data = await WordService.getStudyStats()
    this.stats = data
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
      // 顶部栏
      this.TopBar()

      // 内容区
      Scroll() {
        Column() {
          // 今日概览卡片
          this.TodayOverviewCard()

          // 环形进度区
          this.RingProgressSection()

          // 详细统计卡片
          this.DetailStatsCard()
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

  /** 顶部导航栏 */
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

  /** 今日概览卡片 */
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

  /** 环形进度区 - 正确率 */
  @Builder
  RingProgressSection() {
    Column() {
      Text('学习正确率')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.MD })

      // 环形进度条
      Stack() {
        Progress({
          value: this.stats.correctRate,
          total: 100,
          type: ProgressType.Ring
        })
          .width(140)
          .height(140)
          .style({ strokeWidth: 10 })
          .color(ColorConst.PRIMARY)

        Column() {
          Text(`${this.stats.correctRate}%`)
            .fontSize(FontSizeConst.LOGO)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConst.PRIMARY)

          Text('正确率')
            .fontSize(FontSizeConst.CAPTION)
            .fontColor(ColorConst.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ top: SpacingConst.LG, bottom: SpacingConst.LG })
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .alignItems(HorizontalAlign.Center)
    .margin({ top: SpacingConst.MD })
  }

  /** 详细统计信息 */
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
      this.DetailDivider()
      this.DetailRow('正确率', `${this.stats.correctRate}%`)
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
}
