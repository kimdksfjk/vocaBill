import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { StudyStats } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'
import { ProgressBar } from '../components/ProgressBar'

/**
 * 首页 - 展示Logo、今日学习数量、学习进度、开始学习按钮
 */
@Entry
@Component
struct HomePage {
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

  async onPageShow(): Promise<void> {
    try {
      const data = await WordService.getStudyStats()
      this.stats = data
    } catch (err) {
      // 失败时保留现有数据不变
    }
  }

  private async loadData(): Promise<void> {
    this.isLoading = true
    // 预热词库（已加载则直接返回）
    try {
      await WordService.preloadFullBank()
    } catch (err) {
      // 词库加载失败不阻塞首页
    }
    const data = await WordService.getStudyStats()
    this.stats = data
    this.isLoading = false
  }

  build() {
    Column() {
      if (this.isLoading) {
        LoadingView({ tip: '加载中...' })
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
    Scroll() {
      Column() {
        // Logo 区域
        this.LogoSection()

        // 今日学习统计卡片
        this.StatsCard()

        // 学习进度卡片
        this.ProgressCard()

        // 学习入口按钮组
        this.ActionButtons()

        // 底部导航入口
        this.NavEntries()
      }
      .width('100%')
      .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  /** Logo 与标题区 */
  @Builder
  LogoSection() {
    Column() {
      // Logo 图标
      Text('V')
        .fontSize(FontSizeConst.LOGO)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(72)
        .height(72)
        .textAlign(TextAlign.Center)
        .borderRadius(RadiusConst.LG)
        .backgroundColor(ColorConst.PRIMARY)
        .shadow({
          radius: 12,
          color: '#334CAF50',
          offsetY: 4
        })
        .margin({ top: SpacingConst.XXL })

      Text('VocaBill 背单词')
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ top: SpacingConst.MD })

      Text('每天进步一点点')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .margin({ top: SpacingConst.XS })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  /** 今日统计卡片 */
  @Builder
  StatsCard() {
    Row() {
      this.StatItem(this.fmtStat(this.stats.todayCount), '今日已学')
      this.StatDivider()
      this.StatItem(this.fmtStat(this.stats.totalCount), '累计学习')
    }
    .width('100%')
    .padding({ top: SpacingConst.LG, bottom: SpacingConst.LG })
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .shadow({
      radius: 6,
      color: '#1A000000',
      offsetY: 2
    })
    .justifyContent(FlexAlign.SpaceEvenly)
    .margin({ top: SpacingConst.XL })
  }

  /** 格式化统计数值，-1 表示加载失败 */
  private fmtStat(value: number): string {
    if (value < 0) {
      return '--'
    }
    return value.toString()
  }

  @Builder
  StatItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.PRIMARY)

      Text(label)
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .margin({ top: SpacingConst.XS })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .onClick(() => {
      RouterUtil.toStats()
    })
  }

  @Builder
  StatDivider() {
    Divider()
      .vertical(true)
      .strokeWidth(1)
      .color(ColorConst.DIVIDER)
      .height(36)
  }

  /** 进度卡片 */
  @Builder
  ProgressCard() {
    Column() {
      Row() {
        Text('今日学习进度')
          .fontSize(FontSizeConst.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConst.TEXT_PRIMARY)

        Blank()

        Text(`${this.stats.masteredCount} 词已掌握`)
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.PRIMARY)
      }
      .width('100%')

      ProgressBar({
        current: this.stats.todayCount >= 0 ? this.stats.todayCount : 0,
        total: this.stats.todayGoal,
        showText: true
      }).margin({ top: SpacingConst.MD })
    }
    .width('100%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .shadow({
      radius: 6,
      color: '#1A000000',
      offsetY: 2
    })
    .margin({ top: SpacingConst.MD })
  }

  /** 学习入口按钮组 */
  @Builder
  ActionButtons() {
    Row() {
      // 随手背入口
      Button() {
        Column() {
          Text('随手背')
            .fontSize(FontSizeConst.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .height(64)
      .backgroundColor('#81C784') // 柔和的绿色
      .borderRadius(RadiusConst.XL)
      .shadow({
        radius: 8,
        color: '#3381C784',
        offsetY: 4
      })
      .margin({ right: SpacingConst.MD })
      .onClick(() => {
        RouterUtil.toReview()
      })

      // 深度背词入口
      Button() {
        Row() {
          Text('深度背词')
            .fontSize(FontSizeConst.HEADLINE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(' →')
            .fontSize(FontSizeConst.TITLE)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(2)
      .height(64)
      .backgroundColor(ColorConst.PRIMARY)
      .borderRadius(RadiusConst.XL)
      .shadow({
        radius: 12,
        color: '#334CAF50',
        offsetY: 6
      })
      .onClick(() => {
        RouterUtil.push('pages/DeepLearningPage')
      })
    }
    .width('100%')
    .margin({ top: SpacingConst.XXL })
  }

  /** 底部导航入口 */
  @Builder
  NavEntries() {
    Row() {
      // 统计入口
      Column() {
        Text('📊')
          .fontSize(24)
        Text('学习统计')
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.XS })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: SpacingConst.LG, right: SpacingConst.LG, top: SpacingConst.SM, bottom: SpacingConst.SM })
      .borderRadius(RadiusConst.MD)
      .onClick(() => {
        RouterUtil.toStats()
      })

      // 喜欢的词本入口
      Column() {
        Text('⭐')
          .fontSize(24)
        Text('喜欢的词本')
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.XS })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: SpacingConst.LG, right: SpacingConst.LG, top: SpacingConst.SM, bottom: SpacingConst.SM })
      .borderRadius(RadiusConst.MD)
      .onClick(() => {
        RouterUtil.push(RouteConst.FAVORITES)
      })

      // 设置入口
      Column() {
        Text('⚙')
          .fontSize(24)
        Text('设置')
          .fontSize(FontSizeConst.CAPTION)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.XS })
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: SpacingConst.LG, right: SpacingConst.LG, top: SpacingConst.SM, bottom: SpacingConst.SM })
      .borderRadius(RadiusConst.MD)
      .onClick(() => {
        RouterUtil.toSettings()
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ top: SpacingConst.XXL, bottom: SpacingConst.XXL })
  }
}
