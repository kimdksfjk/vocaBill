import { ColorConst, DefaultConst, FontSizeConst, RadiusConst, SpacingConst, RouteConst } from '../common/constants/CommonConstants'
import { WordService } from '../services/WordService'
import { UserService } from '../services/UserService'
import { RouterUtil } from '../common/router/RouterUtil'
import { User } from '../models/User'
import { LoadingView } from '../components/LoadingView'
import { bundleManager } from '@kit.AbilityKit'
import promptAction from '@ohos.promptAction'

/**
 * 设置页 - 每日目标、学习提醒、发音设置、账户管理、数据重置
 */
@Entry
@Component
struct SettingsPage {
  @State isLoading: boolean = true
  @State dailyGoal: number = DefaultConst.DAILY_GOAL
  @State showResetDialog: boolean = false
  @State showLogoutDialog: boolean = false
  @State showReminderDialog: boolean = false
  @State showPronunciationDialog: boolean = false
  @State currentUser: User | null = null
  @State reminderEnabled: boolean = false
  @State pronunciationPref: string = 'british'
  @State versionName: string = '1.0.0'

  aboutToAppear(): void {
    this.loadSettings()
  }

  async onPageShow(): Promise<void> {
    try {
      const goal = await WordService.getDailyGoal()
      this.dailyGoal = goal
      const user = await UserService.getCurrentUser()
      this.currentUser = user
      const reminderEnabled = await WordService.getReminderEnabled()
      this.reminderEnabled = reminderEnabled
      const pronPref = await WordService.getPronunciationPref()
      this.pronunciationPref = pronPref
    } catch (err) {
      // 失败时保留现有数据
    }
  }

  private async loadSettings(): Promise<void> {
    this.isLoading = true
    const goal = await WordService.getDailyGoal()
    this.dailyGoal = goal
    const user = await UserService.getCurrentUser()
    this.currentUser = user
    const reminderEnabled = await WordService.getReminderEnabled()
    this.reminderEnabled = reminderEnabled
    const pronPref = await WordService.getPronunciationPref()
    this.pronunciationPref = pronPref
    // 动态获取版本号
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      this.versionName = bundleInfo.versionName
    } catch (err) {
      this.versionName = '1.0.0'
    }
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
      const goal = await WordService.getDailyGoal()
      this.dailyGoal = goal
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

      // 退出登录确认弹窗
      if (this.showLogoutDialog) {
        this.LogoutDialogMask()
        this.LogoutDialogPanel()
      }

      // 学习提醒选择弹窗
      if (this.showReminderDialog) {
        this.ReminderDialogMask()
        this.ReminderDialogPanel()
      }

      // 发音设置选择弹窗
      if (this.showPronunciationDialog) {
        this.PronunciationDialogMask()
        this.PronunciationDialogPanel()
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

          // 账户管理
          this.AccountSection()

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
          Text(this.versionName)
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
          Text(this.reminderEnabled ? '开启' : '关闭')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
            .margin({ right: SpacingConst.XS })
          Text('>')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
        .onClick(() => {
          this.showReminderDialog = true
        })

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        Row() {
          Text('发音设置')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text(this.pronunciationPref === 'british' ? '英式' : '美式')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
            .margin({ right: SpacingConst.XS })
          Text('>')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_HINT)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
        .onClick(() => {
          this.showPronunciationDialog = true
        })
      }
      .width('100%')
      .backgroundColor(ColorConst.BG_CARD)
      .borderRadius(RadiusConst.LG)
    }
    .width('100%')
    .margin({ top: SpacingConst.MD })
  }

  /** 账户管理章节 */
  @Builder
  AccountSection() {
    Column() {
      Text('账户')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .padding({ left: SpacingConst.SM, bottom: SpacingConst.SM })
        .alignSelf(ItemAlign.Start)

      Column() {
        Row() {
          Text('当前用户')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_PRIMARY)
          Blank()
          Text(this.currentUser ? this.currentUser.username : '未登录')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        Row() {
          Text('退出登录')
            .fontSize(FontSizeConst.BODY)
            .fontColor(ColorConst.DANGER)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.MD })
        .onClick(() => {
          this.showLogoutDialog = true
        })
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

  /** 退出登录确认弹窗-遮罩 */
  @Builder
  LogoutDialogMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.showLogoutDialog = false
      })
  }

  /** 退出登录确认弹窗-面板 */
  @Builder
  LogoutDialogPanel() {
    Column() {
      Text('确认退出')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.SM })

      Text('退出登录后需重新登录才能使用。确定退出吗？')
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
            this.showLogoutDialog = false
          })

        Blank()
          .width(SpacingConst.MD)

        Button('确认退出')
          .fontSize(FontSizeConst.BODY)
          .backgroundColor(ColorConst.DANGER)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(44)
          .borderRadius(RadiusConst.SM)
          .onClick(() => {
            this.onLogout()
          })
      }
      .width('100%')
    }
    .width('80%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
  }

  /** 退出登录处理 */
  private async onLogout(): Promise<void> {
    await UserService.logout()
    this.showLogoutDialog = false
    promptAction.showToast({ message: '已退出登录', duration: 1500 })
    RouterUtil.replace(RouteConst.INDEX)
  }

  /** 学习提醒弹窗-遮罩 */
  @Builder
  ReminderDialogMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.showReminderDialog = false
      })
  }

  /** 学习提醒弹窗-面板 */
  @Builder
  ReminderDialogPanel() {
    Column() {
      Text('学习提醒')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.LG })

      Row() {
        Text(this.reminderEnabled ? '开启' : '关闭')
          .fontSize(FontSizeConst.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.reminderEnabled ? ColorConst.PRIMARY : ColorConst.TEXT_SECONDARY)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: SpacingConst.LG, bottom: SpacingConst.LG })
      .backgroundColor(this.reminderEnabled ? '#E8F5E9' : '#F5F5F5')
      .borderRadius(RadiusConst.MD)
      .onClick(async () => {
        const newVal = !this.reminderEnabled
        const ok = await WordService.setReminderEnabled(newVal)
        if (ok) {
          this.reminderEnabled = newVal
          if (newVal) {
            promptAction.showToast({ message: '学习提醒已开启', duration: 1500 })
          } else {
            promptAction.showToast({ message: '学习提醒已关闭', duration: 1500 })
          }
        }
        this.showReminderDialog = false
      })

      Text('开启后将在设定的时间提醒您学习')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.TEXT_HINT)
        .margin({ top: SpacingConst.SM })

      Row() {
        Button('关闭')
          .fontSize(FontSizeConst.BODY)
          .backgroundColor(ColorConst.BG_DEFAULT)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .layoutWeight(1)
          .height(44)
          .borderRadius(RadiusConst.SM)
          .onClick(() => {
            this.showReminderDialog = false
          })
      }
      .width('100%')
      .margin({ top: SpacingConst.LG })
    }
    .width('80%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
  }

  /** 发音设置弹窗-遮罩 */
  @Builder
  PronunciationDialogMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .onClick(() => {
        this.showPronunciationDialog = false
      })
  }

  /** 发音设置弹窗-面板 */
  @Builder
  PronunciationDialogPanel() {
    Column() {
      Text('发音设置')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.LG })

      Row() {
        Text('英式发音')
          .fontSize(FontSizeConst.BODY)
          .fontColor(this.pronunciationPref === 'british' ? ColorConst.PRIMARY : ColorConst.TEXT_PRIMARY)
        Blank()
        if (this.pronunciationPref === 'british') {
          Text('✓')
            .fontSize(FontSizeConst.TITLE)
            .fontColor(ColorConst.PRIMARY)
        }
      }
      .width('100%')
      .padding({ top: SpacingConst.MD, bottom: SpacingConst.MD })
      .onClick(async () => {
        await WordService.setPronunciationPref('british')
        this.pronunciationPref = 'british'
        this.showPronunciationDialog = false
        promptAction.showToast({ message: '已切换为英式发音', duration: 1500 })
      })

      Divider().strokeWidth(0.5).color(ColorConst.DIVIDER)

      Row() {
        Text('美式发音')
          .fontSize(FontSizeConst.BODY)
          .fontColor(this.pronunciationPref === 'american' ? ColorConst.PRIMARY : ColorConst.TEXT_PRIMARY)
        Blank()
        if (this.pronunciationPref === 'american') {
          Text('✓')
            .fontSize(FontSizeConst.TITLE)
            .fontColor(ColorConst.PRIMARY)
        }
      }
      .width('100%')
      .padding({ top: SpacingConst.MD, bottom: SpacingConst.MD })
      .onClick(async () => {
        await WordService.setPronunciationPref('american')
        this.pronunciationPref = 'american'
        this.showPronunciationDialog = false
        promptAction.showToast({ message: '已切换为美式发音', duration: 1500 })
      })

      Row() {
        Button('取消')
          .fontSize(FontSizeConst.BODY)
          .backgroundColor(ColorConst.BG_DEFAULT)
          .fontColor(ColorConst.TEXT_PRIMARY)
          .layoutWeight(1)
          .height(44)
          .borderRadius(RadiusConst.SM)
          .onClick(() => {
            this.showPronunciationDialog = false
          })
      }
      .width('100%')
      .margin({ top: SpacingConst.LG })
    }
    .width('80%')
    .padding(SpacingConst.LG)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
  }
}
