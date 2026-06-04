import router from '@ohos.router'
import { RouteConst } from '../constants/CommonConstants'

/**
 * 路由工具类
 */
export class RouterUtil {
  static push(url: string, params?: Object): void {
    router.pushUrl({
      url: url,
      params: params
    })
  }

  static replace(url: string, params?: Object): void {
    router.replaceUrl({
      url: url,
      params: params
    })
  }

  static back(): void {
    router.back()
  }

  static toHome(params?: Object): void {
    RouterUtil.push(RouteConst.HOME, params)
  }

  static toReview(params?: Object): void {
    RouterUtil.push(RouteConst.REVIEW, params)
  }

  static toStats(params?: Object): void {
    RouterUtil.push(RouteConst.STATS, params)
  }

  static toSettings(params?: Object): void {
    RouterUtil.push(RouteConst.SETTINGS, params)
  }

  /** 获取路由传递的参数 */
  static getParams(): Object | undefined {
    return router.getParams()
  }
}
