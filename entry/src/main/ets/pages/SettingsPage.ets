import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'

/**
 * 设置页 - 每日目标设置、关于应用、数据重置
 */
@Entry
@Component
struct SettingsPage {
  @State isLoading: boolean = true
  @State dailyGoal: number = DefaultConst.DAILY_GOAL
  @State showResetDialog: boolean = false

  aboutToAppear(): void {
    this.loadSettings()
  }

  onPageShow(): void {
    this.reloadGoal()
  }

  private async reloadGoal(): Promise<void> {
    const goal = await WordService.getDailyGoal()
    this.dailyGoal = goal
  }

  private async loadSettings(): Promise<void> {
    this.isLoading = true
    const goal = await WordService.getDailyGoal()
    this.dailyGoal = goal
    this.isLoading = false
  }

  private async onGoalChanged(value: number): Promise<void> {
    this.dailyGoal = value
    const ok = await WordService.setDailyGoal(value)
    if (!ok) {
      // 写 DB 失败，回退到旧值
      const saved = await WordService.getDailyGoal()
      this.dailyGoal = saved
    }
  }

  private async onResetData(): Promise<void> {
    const ok = await WordService.resetAllData()
    if (ok) {
      this.showResetDialog = false
      this.reloadGoal()
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.isLoading) {
          LoadingView({ tip: '加载设置...' })
        } else {
          this.MainContent()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorConst.BG_DEFAULT)

      // 重置确认弹窗
      if (this.showResetDialog) {
        this.ResetDialogMask()
        this.ResetDialogPanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MainContent() {
    Column() {
      // 顶部栏
      this.TopBar()

      // 设置内容
      Scroll() {
        Column() {
          // 每日目标设置
          this.GoalSection()

          // 通用设置
          this.GeneralSection()

          // 数据管理
          this.DataSection()
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

      Text('设置')
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

  /** 每日目标设置章节 */
  @Builder
  GoalSection() {
    Column() {
      Text('每日目标')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .padding({ left: SpacingConst.SM, bottom: SpacingConst.SM })
        .alignSelf(ItemAlign.Start)

      Column() {
        Row() {
          Text('每日学习量')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)

          Blank()

          // 减少按钮
          Button() {
            Text('-')
              .fontSize(FontSizeConst.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.dailyGoal > 5 ? ColorConst.PRIMARY : ColorConst.TEXT_HINT)
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.dailyGoal > 5) {
              this.onGoalChanged(this.dailyGoal - 5)
            }
          })

          // 目标值
          Text(`${this.dailyGoal}`)
            .fontSize(FontSizeConst.HEADLINE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConst.PRIMARY)
            .width(48)
            .textAlign(TextAlign.Center)

          // 增加按钮
          Button() {
            Text('+')
              .fontSize(FontSizeConst.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.dailyGoal < 200 ? ColorConst.PRIMARY : ColorConst.TEXT_HINT)
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.dailyGoal < 200) {
              this.onGoalChanged(this.dailyGoal + 5)
            }
          })
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
      }
      .width('100%')
      .backgroundColor(ColorConst.BG_CARD)
      .borderRadius(RadiusConst.LG)
    }
    .width('100%')
    .margin({ top: SpacingConst.MD })
  }

  /** 通用设置章节 */
  @Builder
  GeneralSection() {
    Column() {
      Text('通用')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .padding({ left: SpacingConst.SM, bottom: SpacingConst.SM })
        .alignSelf(ItemAlign.Start)

      Column() {
        Row() {
          Text('应用名称')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text('VocaBill')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        Row() {
          Text('版本号')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text('1.0.0')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        Row() {
          Text('学习提醒')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text('关闭')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
            .margin({ right: SpacingConst.XS })
          Text('>')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        Row() {
          Text('发音设置')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text('英式')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
            .margin({ right: SpacingConst.XS })
          Text('>')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
      }
      .width('100%')
      .backgroundColor(ColorConst.BG_CARD)
      .borderRadius(RadiusConst.LG)
    }
    .width('100%')
    .margin({ top: SpacingConst.MD })
  }

  /** 数据管理章节 */
  @Builder
  DataSection() {
    Column() {
      Text('数据管理')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .padding({ left: SpacingConst.SM, bottom: SpacingConst.SM })
        .alignSelf(ItemAlign.Start)

      Column() {
        Row() {
          Text('重置学习数据')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.DANGER)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
        .onClick(() => {
          this.showResetDialog = true
        })
      }
      .width('100%')
      .backgroundColor(ColorConst.BG_CARD)
      .borderRadius(RadiusConst.LG)
    }
    .width('100%')
    .margin({ top: SpacingConst.MD })
  }

  /** 重置确认弹窗-遮罩 */
  @Builder
  ResetDialogMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.showResetDialog = false
      })
  }

  /** 重置确认弹窗-面板 */
  @Builder
  ResetDialogPanel() {
    Column() {
      Text('确认重置')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.SM })

      Text('重置后所有学习数据将被清除，此操作不可撤销。')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .margin({ bottom: SpacingConst.LG })

      Row() {
        Button('取消')
          .fontSize(FontSizeConst.BODY)
          .backgroundColor(ColorConst.BG_DEFAULT)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .layoutWeight(1)
          .height(44)
          .borderRadius(RadiusConst.SM)
          .onClick(() => {
            this.showResetDialog = false
          })

        Blank()
          .width(SpacingConst.MD)

        Button('确认重置')
          .fontSize(FontSizeConst.BODY)
          .backgroundColor(ColorConst.DANGER)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(44)
          .borderRadius(RadiusConst.SM)
          .onClick(() => {
            this.onResetData()
          })
      }
      .width('100%')
    }
    .width('80%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
  }
}
