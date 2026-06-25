/**
 * 公共常量定义
 */

/** 应用配色 */
export class ColorConst {
  static readonly PRIMARY = '#4CAF50'
  static readonly PRIMARY_LIGHT = '#81C784'
  static readonly SECONDARY = '#2196F3'
  static readonly SECONDARY_LIGHT = '#64B5F6'
  static readonly DANGER = '#FF5252'
  static readonly WARNING = '#FFC107'
  static readonly BG_DEFAULT = '#F5F5F5'
  static readonly BG_CARD = '#FFFFFF'
  static readonly TEXT_PRIMARY = '#212121'
  static readonly TEXT_SECONDARY = '#757575'
  static readonly TEXT_HINT = '#BDBDBD'
  static readonly DIVIDER = '#EEEEEE'
  static readonly GREEN_BG = '#E8F5E9'
  static readonly RED_BG = '#FFEBEE'
  static readonly BLUE_BG = '#E3F2FD'
  static readonly YELLOW_BG = '#FFF8E1'
}

/** 间距 */
export class SpacingConst {
  static readonly XS = 4
  static readonly SM = 8
  static readonly MD = 16
  static readonly LG = 24
  static readonly XL = 32
  static readonly XXL = 48
}

/** 字体大小 */
export class FontSizeConst {
  static readonly CAPTION = 12
  static readonly BODY = 14
  static readonly SUBTITLE = 16
  static readonly TITLE = 20
  static readonly HEADLINE = 24
  static readonly WORD = 36
  static readonly LOGO = 48
}

/** 圆角 */
export class RadiusConst {
  static readonly SM = 8
  static readonly MD = 12
  static readonly LG = 16
  static readonly XL = 24
  static readonly FULL = 50
}

/** 页面路由路径 */
export class RouteConst {
  static readonly INDEX = 'pages/Index'
  static readonly HOME = 'pages/HomePage'
  static readonly REVIEW = 'pages/ReviewPage'
  static readonly STATS = 'pages/StatsPage'
  static readonly SETTINGS = 'pages/SettingsPage'
  static readonly LOGIN = 'pages/LoginPage'
  static readonly REGISTER = 'pages/RegisterPage'
  static readonly FAVORITES = 'pages/FavoriteWordsPage'
}

/** 默认设置 */
export class DefaultConst {
  static readonly DAILY_GOAL = 20
  static readonly AUTO_NEXT_DELAY = 10  // 选择后自动下一词的延迟(ms)
}
