import { ColorConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'

/**
 * 加载视图组件 - 显示加载动画与提示文字
 * 用于数据加载中的过渡状态
 */
@Component
export struct LoadingView {
  @Prop tip: string = '加载中...'
  @State private rotateAngle: number = 0

  aboutToAppear(): void {
    this.startRotation()
  }

  private startRotation(): void {
    setInterval(() => {
      this.rotateAngle = (this.rotateAngle + 30) % 360
    }, 80)
  }

  build() {
    Column() {
      Stack() {
        // 旋转圆环
        Circle()
          .width(48)
          .height(48)
          .fill(Color.Transparent)
          .stroke(ColorConst.PRIMARY)
          .strokeWidth(3)
          .strokeDashArray([Math.PI * 48 * 0.7, Math.PI * 48 * 0.3])
          .rotate({ angle: this.rotateAngle })

        // 中心点
        Circle()
          .width(8)
          .height(8)
          .fill(ColorConst.PRIMARY_LIGHT)
      }

      if (this.tip) {
        Text(this.tip)
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.TEXT_SECONDARY)
          .margin({ top: SpacingConst.MD })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
