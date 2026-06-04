import { ColorConst, FontSizeConst, RadiusConst, RouteConst, SpacingConst } from '../common/constants/CommonConstants'
import { RouterUtil } from '../common/router/RouterUtil'

/**
 * 入口页 - 启动后显示Logo并自动跳转到首页
 */
@Entry
@Component
struct Index {
  @State logoOpacity: number = 0

  aboutToAppear(): void {
    // Logo渐显动画
    this.logoOpacity = 1

    // 延迟跳转到首页
    setTimeout(() => {
      RouterUtil.replace(RouteConst.HOME)
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
