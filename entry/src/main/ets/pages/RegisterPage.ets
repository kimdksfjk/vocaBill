import { ColorConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { UserService } from '../services/UserService'
import { RouterUtil } from '../common/router/RouterUtil'
import promptAction from '@ohos.promptAction'

/**
 * 注册页
 */
@Entry
@Component
struct RegisterPage {
  @State username: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State showPassword: boolean = false
  @State showConfirmPassword: boolean = false
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部栏
      this.TopBar()

      // 表单区域
      Scroll() {
        Column() {
          // 表单卡片
          Column() {
            // 用户名输入框
            Row() {
              TextInput({ text: this.username, placeholder: '请输入用户名（2-20个字符）' })
                .fontSize(FontSizeConst.BODY)
                .type(InputType.Normal)
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(48)
                .maxLength(20)
                .onChange((value: string) => {
                  this.username = value
                })
            }
            .width('100%')
            .padding({ left: SpacingConst.MD, right: SpacingConst.MD })

            Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

            // 密码输入框
            Row() {
              TextInput({ text: this.password, placeholder: '请输入密码（至少6位）' })
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

            Divider().strokeWidth(0.5).color(ColorConst.DIVIDER).margin({ left: SpacingConst.MD })

            // 确认密码输入框
            Row() {
              TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
                .fontSize(FontSizeConst.BODY)
                .type(InputType.Password)
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(48)
                .onChange((value: string) => {
                  this.confirmPassword = value
                })
            }
            .width('100%')
            .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
          }
          .width('100%')
          .backgroundColor(ColorConst.BG_CARD)
          .borderRadius(RadiusConst.LG)
          .margin({ top: SpacingConst.LG })

          // 注册按钮
          Button() {
            Text(this.isLoading ? '注册中...' : '注 册')
              .fontSize(FontSizeConst.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width('100%')
          .height(52)
          .backgroundColor(this.isLoading ? ColorConst.PRIMARY_LIGHT : ColorConst.PRIMARY)
          .borderRadius(RadiusConst.XL)
          .margin({ top: SpacingConst.XL })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleRegister()
          })

          // 去登录
          Row() {
            Text('已有账号？')
              .fontSize(FontSizeConst.BODY)
              .fontColor(ColorConst.TEXT_SECONDARY)

            Text('去登录')
              .fontSize(FontSizeConst.BODY)
              .fontColor(ColorConst.PRIMARY)
              .fontWeight(FontWeight.Medium)
              .margin({ left: SpacingConst.XS })
              .onClick(() => {
                RouterUtil.back()
              })
          }
          .margin({ top: SpacingConst.LG })
        }
        .width('100%')
        .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
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

      Text('注册账号')
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

  /** 处理注册 */
  private async handleRegister(): Promise<void> {
    if (this.isLoading) {
      return
    }

    // 前端校验
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致', duration: 2000 })
      return
    }

    this.isLoading = true
    try {
      const result = await UserService.register(this.username, this.password)
      if (result.success) {
        promptAction.showToast({ message: '注册成功', duration: 1500 })
        RouterUtil.replace(RouteConst.HOME)
      } else {
        promptAction.showToast({ message: result.message, duration: 2000 })
      }
    } catch (err) {
      promptAction.showToast({ message: '注册失败，请稍后重试', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }
}
