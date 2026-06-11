import { ColorConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { RouterUtil } from '../common/router/RouterUtil'
import { UserService } from '../services/UserService'
import { WordService } from '../services/WordService'

/**
 * 入口页 - 启动后显示Logo，预加载词库，根据登录状态跳转
 */
@Entry
@Component
struct Index {
  @State logoOpacity: number = 0

  aboutToAppear(): void {
    this.logoOpacity = 1
    this.bootstrap()
  }

  private async bootstrap(): Promise<void> {
    // 并行：检查登录 + 预加载词库
    const isLoggedIn = await UserService.isLoggedIn().catch(() => false)
    // 已登录则立即开始预加载词库
    if (isLoggedIn) {
      WordService.preloadFullBank().catch(() => {
        // 预加载失败不阻塞跳转
      })
    }

    // 延迟 1.2s 后跳转（保持动画效果）
    setTimeout(() => {
      if (isLoggedIn) {
        RouterUtil.replace(RouteConst.HOME)
      } else {
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
