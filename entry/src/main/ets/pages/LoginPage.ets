import { ColorConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { UserService } from '../services/UserService'
import { RouterUtil } from '../common/router/RouterUtil'
import promptAction from '@ohos.promptAction'

/**
 * 登录页
 */
@Entry
@Component
struct LoginPage {
  @State username: string = ''
  @State password: string = ''
  @State showPassword: boolean = false
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部区域：Logo
      this.LogoSection()

      // 表单区域
      Column() {
        // 用户名输入框
        this.InputItem('用户名', '请输入用户名', this.username, (value: string) => {
          this.username = value
        }, false)

        Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

        // 密码输入框
        Row() {
          TextInput({ text: this.password, placeholder: '请输入密码' })
            .fontSize(FontSizeConst.BODY)
            .type(InputType.Password)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .height(48)
            .onChange((value: string) => {
              this.password = value
            })
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
      }
      .width('100%')
      .backgroundColor(ColorConst.BG_CARD)
      .borderRadius(RadiusConst.LG)
      .margin({ top: SpacingConst.XXL, left: SpacingConst.MD, right: SpacingConst.MD })

      // 登录按钮
      Button() {
        Text(this.isLoading ? '登录中...' : '登 录')
          .fontSize(FontSizeConst.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(52)
      .backgroundColor(this.isLoading ? ColorConst.PRIMARY_LIGHT : ColorConst.PRIMARY)
      .borderRadius(RadiusConst.XL)
      .margin({ top: SpacingConst.XL, left: SpacingConst.MD, right: SpacingConst.MD })
      .enabled(!this.isLoading)
      .onClick(() => {
        this.handleLogin()
      })

      // 去注册
      Row() {
        Text('还没有账号？')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_SECONDARY)

        Text('去注册')
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .margin({ left: SpacingConst.XS })
          .onClick(() => {
            RouterUtil.toRegister()
          })
      }
      .margin({ top: SpacingConst.LG })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
    .justifyContent(FlexAlign.Center)
  }

  /** Logo 区域 */
  @Builder
  LogoSection() {
    Column() {
      Text('V')
        .fontSize(FontSizeConst.LOGO)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(80)
        .height(80)
        .textAlign(TextAlign.Center)
        .borderRadius(RadiusConst.LG)
        .backgroundColor(ColorConst.PRIMARY)

      Text('VocaBill 背单词')
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ top: SpacingConst.MD })

      Text('登录后开始学习')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .margin({ top: SpacingConst.XS })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /** 输入项 */
  @Builder
  InputItem(label: string, placeholder: string, value: string, onChange: (value: string) => void, isPassword: boolean) {
    Row() {
      TextInput({ text: value, placeholder: placeholder })
        .fontSize(FontSizeConst.BODY)
        .type(InputType.Normal)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(48)
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
  }

  /** 处理登录 */
  private async handleLogin(): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    try {
      const result = await UserService.login(this.username, this.password)
      if (result.success) {
        promptAction.showToast({ message: '登录成功', duration: 1500 })
        RouterUtil.replace(RouteConst.HOME)
      } else {
        promptAction.showToast({ message: result.message, duration: 2000 })
      }
    } catch (err) {
      promptAction.showToast({ message: '登录失败，请稍后重试', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }
}
