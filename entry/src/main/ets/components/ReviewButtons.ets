import { ColorConst, FontSizeConst, RadiusConst, SpacingConst } from '../common/constants/CommonConstants'

/**
 * 复习按钮组件 - "认识" / "不认识"
 */
@Component
export struct ReviewButtons {
  @Prop showMeaning: boolean = false   // 是否已显示释义，控制是否可点击
  onKnown: () => void = () => {}
  onUnknown: () => void = () => {}

  build() {
    Row() {
      // "不认识" 按钮
      Button() {
        Text('不认识')
          .fontSize(FontSizeConst.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
      }
      .width('40%')
      .height(52)
      .backgroundColor(ColorConst.DANGER)
      .borderRadius(RadiusConst.XL)
      .enabled(this.showMeaning)
      .opacity(this.showMeaning ? 1 : 0.4)
      .shadow({
        radius: 8,
        color: '#33FF5252',
        offsetY: 4
      })
      .onClick(() => {
        if (this.showMeaning) {
          this.onUnknown()
        }
      })

      Blank()

      // "认识" 按钮
      Button() {
        Text('认识')
          .fontSize(FontSizeConst.TITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
      }
      .width('40%')
      .height(52)
      .backgroundColor(ColorConst.SECONDARY)
      .borderRadius(RadiusConst.XL)
      .enabled(this.showMeaning)
      .opacity(this.showMeaning ? 1 : 0.4)
      .shadow({
        radius: 8,
        color: '#332196F3',
        offsetY: 4
      })
      .onClick(() => {
        if (this.showMeaning) {
          this.onKnown()
        }
      })
    }
    .width('100%')
    .padding({ left: SpacingConst.LG, right: SpacingConst.LG })
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}
