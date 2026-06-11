import { ColorConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { RouterUtil } from '../common/router/RouterUtil'
import { UserService } from '../services/UserService'

/**
 * 入口页 - 启动后显示Logo，根据登录状态跳转
 */
@Entry
@Component
struct Index {
  @State logoOpacity: number = 0

  aboutToAppear(): void {
    // Logo渐显动画
    this.logoOpacity = 1

    // 检查登录状态后跳转
    setTimeout(async () => {
      try {
        const isLoggedIn = await UserService.isLoggedIn()
        if (isLoggedIn) {
          RouterUtil.replace(RouteConst.HOME)
        } else {
          RouterUtil.replace(RouteConst.LOGIN)
        }
      } catch (err) {
        // 出错时默认跳转到登录页
        RouterUtil.replace(RouteConst.LOGIN)
      }
    }, 1200)
  }

  build() {
    Column() {
      // Logo
      Text('V')
        .fontSize(FontSizeConst.LOGO)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(80)
        .height(80)
        .textAlign(TextAlign.Center)
        .borderRadius(RadiusConst.LG)
        .backgroundColor(ColorConst.PRIMARY)
        .opacity(this.logoOpacity)

      Text('VocaBill 背单词')
        .fontSize(FontSizeConst.HEADLINE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.PRIMARY)
        .margin({ top: SpacingConst.MD })
        .opacity(this.logoOpacity)

      Text('每天进步一点点')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
        .margin({ top: SpacingConst.XS })
        .opacity(this.logoOpacity)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
