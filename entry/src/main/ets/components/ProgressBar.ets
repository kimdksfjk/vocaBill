import { ColorConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'

/**
 * 进度条组件 - 显示学习进度（如 "5/20"）
 */
@Component
export struct ProgressBar {
  @Prop current: number = 0    // 当前进度
  @Prop total: number = 1      // 总数
  @Prop showText: boolean = true

  build() {
    Column() {
      Row() {
        // 进度条主体
        Progress({
          value: this.current,
          total: this.total,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(6)
          .style({ strokeWidth: 6 })
          .color(ColorConst.PRIMARY)
          .backgroundColor(ColorConst.DIVIDER)
      }
      .width('100%')

      if (this.showText) {
        Row() {
          Text(`${this.current} / ${this.total}`)
            .fontSize(FontSizeConst.CAPTION)
            .fontColor(ColorConst.TEXT_SECONDARY)

          Blank()

          Text(`${Math.round((this.current / this.total) * 100)}%`)
            .fontSize(FontSizeConst.CAPTION)
            .fontColor(ColorConst.PRIMARY)
        }
        .width('100%')
        .margin({ top: SpacingConst.XS })
      }
    }
    .width('100%')
  }
}
