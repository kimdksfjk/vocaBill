import { ColorConst, FontSizeConst, RadiusConst, SpacingConst, RouteConst } from '../common/constants/CommonConstants'
import { Word } from '../models/Word'
import { WordService } from '../services/WordService'
import { RouterUtil } from '../common/router/RouterUtil'
import { LoadingView } from '../components/LoadingView'
import promptAction from '@ohos.promptAction'

@Entry
@Component
export struct FavoriteWordsPage {
  @State isLoading: boolean = true
  @State favoriteWords: Word[] = []
  
  aboutToAppear(): void {
    this.loadFavorites()
  }

  private async loadFavorites(): Promise<void> {
    this.isLoading = true
    try {
      this.favoriteWords = await WordService.getFavoriteWords()
    } catch (err) {
      console.error(`[FavoriteWordsPage] 加载失败: ${JSON.stringify(err)}`)
    }
    this.isLoading = false
  }

  private async removeFavorite(wordId: number): Promise<void> {
    const ok = await WordService.toggleFavorite(wordId, false)
    if (ok) {
      this.favoriteWords = this.favoriteWords.filter(w => w.id !== wordId)
      promptAction.showToast({ message: '已取消收藏', duration: 1500 })
    }
  }

  build() {
    Column() {
      this.TopBar()

      if (this.isLoading) {
        LoadingView({ tip: '正在加载喜欢的词本...' })
      } else if (this.favoriteWords.length === 0) {
        this.EmptyView()
      } else {
        this.WordList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConst.BG_DEFAULT)
  }

  @Builder
  TopBar() {
    Row() {
      Text('<')
        .fontSize(FontSizeConst.HEADLINE)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .onClick(() => {
          RouterUtil.back()
        })

      Text('喜欢的词本')
        .fontSize(FontSizeConst.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ left: SpacingConst.MD })

      Blank()
      
      Text(`共 ${this.favoriteWords.length} 词`)
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
    }
    .width('100%')
    .height(56)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD })
    .backgroundColor(ColorConst.BG_CARD)
  }

  @Builder
  EmptyView() {
    Column() {
      Text('⭐')
        .fontSize(64)
        .margin({ bottom: SpacingConst.MD })
      Text('还没有收藏的单词哦')
        .fontSize(FontSizeConst.TITLE)
        .fontColor(ColorConst.TEXT_PRIMARY)
        .margin({ bottom: SpacingConst.SM })
      Text('在背词时点击星星即可收藏')
        .fontSize(FontSizeConst.BODY)
        .fontColor(ColorConst.TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  WordList() {
    List({ space: SpacingConst.MD }) {
      ForEach(this.favoriteWords, (word: Word) => {
        ListItem() {
          this.WordItemCard(word)
        }
      }, (word: Word) => word.id.toString())
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: SpacingConst.MD, right: SpacingConst.MD, top: SpacingConst.MD, bottom: SpacingConst.XXL })
  }

  @Builder
  WordItemCard(word: Word) {
    Row() {
      Column() {
        Text(word.word)
          .fontSize(FontSizeConst.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConst.TEXT_PRIMARY)
        
        Row() {
          if (word.ukPhonetic) {
            Text(`英 /${word.ukPhonetic}/`)
              .fontSize(FontSizeConst.CAPTION)
              .fontColor(ColorConst.TEXT_SECONDARY)
              .margin({ right: SpacingConst.SM })
          }
          if (word.usPhonetic) {
            Text(`美 /${word.usPhonetic}/`)
              .fontSize(FontSizeConst.CAPTION)
              .fontColor(ColorConst.TEXT_SECONDARY)
          }
        }
        .margin({ top: SpacingConst.XS, bottom: SpacingConst.XS })

        Text(word.meaning)
          .fontSize(FontSizeConst.BODY)
          .fontColor(ColorConst.PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button('取消收藏')
        .fontSize(FontSizeConst.CAPTION)
        .fontColor(ColorConst.DANGER)
        .backgroundColor(ColorConst.RED_BG)
        .height(32)
        .borderRadius(RadiusConst.SM)
        .margin({ left: SpacingConst.SM })
        .onClick(() => {
          this.removeFavorite(word.id)
        })
    }
    .width('100%')
    .padding(SpacingConst.MD)
    .backgroundColor(ColorConst.BG_CARD)
    .borderRadius(RadiusConst.LG)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetY: 2
    })
  }
}
