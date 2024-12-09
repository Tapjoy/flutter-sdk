import Flutter
import Tapjoy
import UIKit

public class TapjoyOfferwallPlugin: NSObject, FlutterPlugin, TJPlacementDelegate {

  static var placementMap = [String: TJPlacement]()
  let channelName = "tapjoy_offerwall"
  var offerwallDiscover = TapjoyOfferwallDiscover()
  static let instance = TapjoyOfferwallPlugin()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = ChannelManager.shared.registerMethodChannel(forRegistrar: registrar, name: "tapjoy_offerwall")
    let eventChannel = FlutterEventChannel(name: "tapjoy_offerwall_events", binaryMessenger: registrar.messenger())
    ChannelManager.shared.setEventChannel(eventChannel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    TapjoyOfferwallDiscover.shared.registerChannel(with: registrar)

    let factory = TapjoyOfferwallDiscoverViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "tapjoy_offerwall_discover")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      connect(call.arguments as! [String: Any?], result: result)
    case "setDebugEnabled":
      setDebugEnabled(call.arguments as! [String: Any?], result: result)
    case "isConnected":
      isConnected(result)
    case "setUserID":
      setUserID(call.arguments as! [String: Any?], result: result)
    case "getUserID":
      getUserID(result)
    case "getCurrencyBalance":
      getCurrencyBalance(result: result)
    case "spendCurrency":
      spendCurrency(call.arguments as! [String: Any?], result: result)
    case "awardCurrency":
      awardCurrency(call.arguments as! [String: Any?], result: result)
    case "setUserConsent":
      setUserConsent(call.arguments as! [String: Any?], result: result)
    case "getUserConsent":
      getUserConsent(result)
    case "setSubjectToGDPR":
      setSubjectToGDPR(call.arguments as! [String: Any?], result: result)
    case "getSubjectToGDPR":
      getSubjectToGDPR(result)
    case "setBelowConsentAge":
      setBelowConsentAge(call.arguments as! [String: Any?], result: result)
    case "getBelowConsentAge":
      getBelowConsentAge(result)
    case "setUSPrivacy":
      setUSPrivacy(call.arguments as! [String: Any?], result: result)
    case "getUSPrivacy":
      getUSPrivacy(result)
    case "setUserLevel":
        setUserLevel(call.arguments as! [String: Any?], result: result)
    case "getUserLevel":
        getUserLevel(result)
    case "setMaxLevel":
        setMaxLevel(call.arguments as! [String: Any?], result: result)
    case "getMaxLevel":
        getMaxLevel(result)
    case "setUserSegment":
        setUserSegment(call.arguments as! [String: Any?], result: result)
    case "getUserSegment":
        getUserSegment(result)
    case "setUserTags":
        setUserTags(call.arguments as! [String: Any?], result: result)
    case "getUserTags":
        getUserTags(result)
    case "clearUserTags":
        clearUserTags(result)
    case "addUserTag":
        addUserTag(call.arguments as! [String: Any?], result: result)
    case "removeUserTag":
        removeUserTag(call.arguments as! [String: Any?], result: result)
    case "getPlacement":
      getPlacement(call.arguments as! [String: Any?], result: result)
    case "requestContent":
      requestContent(call.arguments as! [String: Any?], result: result)
    case "showContent":
      showContent(call.arguments as! [String: Any?], result: result)
    case "isContentReady":
      isContentReady(call.arguments as! [String: Any?], result: result)
    case "isContentAvailable":
      isContentAvailable(call.arguments as! [String: Any?], result: result)
    case "setEntryPoint":
        setEntryPoint(call.arguments as! [String: Any?], result: result)
    case "getEntryPoint":
        getEntryPoint(call.arguments as! [String: Any?], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func connect(_ args: [String: Any?], result: @escaping FlutterResult) {
    NotificationCenter.default.addObserver(
      self, selector: #selector(tjcConnectSuccess(_:)),
      name: NSNotification.Name(TJC_CONNECT_SUCCESS), object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(tjcConnectFailure(_:)),
      name: NSNotification.Name(TJC_CONNECT_FAILED), object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(tjcConnectWarning(_:)),
      name: NSNotification.Name(TJC_CONNECT_WARNING), object: nil)

    var options = args["options"] as! [String: Any]?
    Tapjoy.sharedTapjoyConnect().plugin = "flutter"
    Tapjoy.connect(args["sdkKey"] as! String, options: options)
    result(nil)
  }

  @objc func tjcConnectSuccess(_ notifyObj: Notification) {
    ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnConnectSuccess", arguments: nil)
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name(TJC_CONNECT_SUCCESS), object: nil)
  }

  @objc func tjcConnectFailure(_ notifyObj: Notification) {
    var code = 0
    var message = ""
    if let error = notifyObj.userInfo?[TJC_CONNECT_USER_INFO_ERROR] as? NSError {
      code = error.code
      message = error.localizedDescription
    }

    ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnConnectFailure", arguments: ["code": code, "message": message])
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name(TJC_CONNECT_FAILED), object: nil)
  }


  @objc func tjcConnectWarning(_ notifyObj: Notification) {
    var code = 0
    var message = ""
    if let error = notifyObj.userInfo?[TJC_CONNECT_USER_INFO_ERROR] as? NSError {
      code = error.code
      message = error.localizedDescription
    }

    ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnConnectWarning", arguments: ["code": code, "message": message])
    NotificationCenter.default.removeObserver(
      self, name: NSNotification.Name(TJC_CONNECT_WARNING), object: nil)
  }

  private func setDebugEnabled(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.setDebugEnabled(args["debugEnabled"] as! Bool)
    result(nil)
  }

  private func isConnected(_ result: @escaping FlutterResult) {
    let res = Tapjoy.isConnected()
    result(res)
  }

  private func setUserID(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.setUserIDWithCompletion(args["userId"] as? String) { [self] success, error in
      if success {
        ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnSetUserIDSuccess", arguments: nil)
      } else {
        ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnSetUserIDFailure", arguments: error?.localizedDescription)
      }
    }
    result(nil)
  }

  private func getUserID(_ result: @escaping FlutterResult) {
      result(Tapjoy.getUserID())
  }

  private func getCurrencyBalance(result: @escaping FlutterResult) {
   Tapjoy.getCurrencyBalance(completion: { [self] parameters, error in
          if let balanceError = error {
              ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnGetCurrencyBalanceFailure", arguments: balanceError.localizedDescription)
          } else {
              guard let params = parameters else {
                  ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnGetCurrencyBalanceFailure", arguments: "Missing parameters")
                  return
              }
              if let currencyName = params["currencyName"], let amount = params["amount"] {
                  ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnGetCurrencyBalanceSuccess", arguments: ["currencyName": currencyName, "balance": amount])
              }
          }
    })
    result(nil)
  }
  
  private func spendCurrency(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.spendCurrency(args["amount"] as? Int32 ?? 0, completion: { [self] parameters, error in
        if let spendError = error {
            ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnSpendCurrencyFailure", arguments: spendError.localizedDescription)
        } else {
            guard let params = parameters else {
                ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnSpendCurrencyFailure", arguments: "Missing parameters")
                return
            }
            if let currencyName = params["currencyName"], let amount = params["amount"] {
               ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnSpendCurrencySuccess", arguments: ["currencyName": currencyName, "balance":  amount])
            }
        }
    })
    result(nil)
  }

  private func awardCurrency(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.awardCurrency(args["amount"] as? Int32 ?? 0, completion: { [self] parameters, error in
         if let awardError = error {
             ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnAwardCurrencyFailure", arguments: awardError.localizedDescription)
         } else {
             guard let params = parameters else {
                 ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnAwardCurrencyFailure", arguments: "Missing parameters")
                 return
             }
             if let currencyName = params["currencyName"], let amount = params["amount"] {
                 ChannelManager.shared.invokeChannelMethod(channelName, "TapjoyOnAwardCurrencySuccess", arguments: ["currencyName": currencyName, "balance":  amount])
             }
         }
     })
    result(nil)
  }

  private static func intToTJStatus(_ intValue: Int) -> TJStatus {
    switch intValue {
    case 0:
      return TJStatus.false
    case 1:
      return TJStatus.true
    default:
      return TJStatus.unknown
    }
  }

  private static func tjStatusToNullableInt(_ status: TJStatus?) -> Int? {
    if(status == nil){
      return nil
    }
    switch status! {
    case TJStatus.false:
      return 0
    case TJStatus.true:
      return 1
    default:
      return 2
    }
  }

  private func setUserConsent(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.getPrivacyPolicy().userConsentStatus = TapjoyOfferwallPlugin.intToTJStatus(
      args["userConsent"] as! Int)
    result(nil)
  }

  private func getUserConsent(_ result: @escaping FlutterResult) {
    let res = Tapjoy.getPrivacyPolicy().userConsentStatus
    result(TapjoyOfferwallPlugin.tjStatusToNullableInt(res))
  }

  private func setSubjectToGDPR(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.getPrivacyPolicy().subjectToGDPRStatus = TapjoyOfferwallPlugin.intToTJStatus(
      args["gdprApplicable"] as! Int)
    result(nil)
  }

  private func getSubjectToGDPR(_ result: @escaping FlutterResult) {
    let res = Tapjoy.getPrivacyPolicy().subjectToGDPRStatus
    result(TapjoyOfferwallPlugin.tjStatusToNullableInt(res))
  }

  private func setBelowConsentAge(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.getPrivacyPolicy().belowConsentAgeStatus = TapjoyOfferwallPlugin.intToTJStatus(
      args["belowConsentAge"] as! Int)
    result(nil)
  }

  private func getBelowConsentAge(_ result: @escaping FlutterResult) {
    let res = Tapjoy.getPrivacyPolicy().belowConsentAgeStatus
    result(TapjoyOfferwallPlugin.tjStatusToNullableInt(res))
  }

  private func setUSPrivacy(_ args: [String: Any?], result: @escaping FlutterResult) {
    Tapjoy.getPrivacyPolicy().usPrivacy = args["privacyValue"] as? String
    result(nil)
  }

  private func getUSPrivacy(_ result: @escaping FlutterResult) {
    let res = Tapjoy.getPrivacyPolicy().usPrivacy
    result(res)
  }

  private func setUserLevel(_ args: [String: Any?], result: @escaping FlutterResult) {
      Tapjoy.setUserLevel(Int32(truncating: args["userLevel"] as! NSNumber))
      result(nil)
  }

  private func getUserLevel(_ result: @escaping FlutterResult) {
      result(Tapjoy.getUserLevel())
  }

  private func setMaxLevel(_ args: [String: Any?], result: @escaping FlutterResult) {
      Tapjoy.setMaxLevel(Int32(truncating: args["maxUserLevel"] as! NSNumber))
  }

  private func getMaxLevel(_ result: @escaping FlutterResult) {
      result(Tapjoy.getMaxLevel())
  }

  private func setUserSegment(_ args: [String: Any?], result: @escaping FlutterResult) {
      Tapjoy.setUserSegment(Segment(rawValue: args["userSegment"] as! Int)!)
      result(nil)
  }

  private func getUserSegment(_ result: @escaping FlutterResult) {
      result(Tapjoy.getUserSegment().rawValue)
  }

  private func setUserTags(_ args: [String: Any?], result: @escaping FlutterResult) {
      let userTags = args["userTags"] as! Array<String>
      Tapjoy.setUserTags(Set(userTags))
      result(nil)
  }

  private func getUserTags(_ result: @escaping FlutterResult) {
      result(Tapjoy.getUserTags()?.compactMap {$0 as? String} as Array<String>?)
  }

  private func clearUserTags(_ result: @escaping FlutterResult) {
      Tapjoy.clearUserTags()
      result(nil)
  }

  private func addUserTag(_ args: [String: Any?], result: @escaping FlutterResult) {
      let userTag = args["userTag"] as! String
      Tapjoy.addUserTag(userTag)
      result(nil)
  }

  private func removeUserTag(_ args: [String: Any?], result: @escaping FlutterResult) {
      let userTag = args["userTag"] as! String
      Tapjoy.removeUserTag(userTag)
      result(nil)
  }

  private func getPlacement(_ args: [String: Any?], result: @escaping FlutterResult) {
    let placementName = args["placementName"] as! String
    let placement = TJPlacement(name: placementName, delegate: self)
    TapjoyOfferwallPlugin.placementMap[placementName] = placement
    result(nil)
  }

  private func requestContent(_ args: [String: Any?], result: @escaping FlutterResult) {
    let placementName = args["placementName"] as! String
    TapjoyOfferwallPlugin.placementMap[placementName]?.requestContent()
    result(nil)
  }

  private func showContent(_ args: [String: Any?], result: @escaping FlutterResult) {
    let placementName = args["placementName"] as! String
    TapjoyOfferwallPlugin.placementMap[placementName]?.showContent(with: nil)
    result(nil)
  }

  private func isContentReady(_ args: [String: Any?], result: @escaping FlutterResult) {
    let placementName = args["placementName"] as! String
    let contentReady = TapjoyOfferwallPlugin.placementMap[placementName]?.isContentReady

    result(contentReady == true)
  }

  private func isContentAvailable(_ args: [String: Any?], result: @escaping FlutterResult) {
    let placementName = args["placementName"] as! String
    let contentAvailable = TapjoyOfferwallPlugin.placementMap[placementName]?.isContentAvailable
    result(contentAvailable == true)
  }

  private func setEntryPoint(_ args: [String: Any?], result: @escaping FlutterResult) {
      let placementName = args["placementName"] as! String
      let entryPoint = args["entryPoint"] as! Int
      if(TJEntryPoint(rawValue: UInt(entryPoint)) != nil){
         TapjoyOfferwallPlugin.placementMap[placementName]?.entryPoint = TJEntryPoint(rawValue: UInt(entryPoint))!
      }
      result(nil)
  }

  private func getEntryPoint(_ args: [String: Any?], result: @escaping FlutterResult) {
      let placementName = args["placementName"] as! String
      let entryPoint = TapjoyOfferwallPlugin.placementMap[placementName]?.entryPoint
      result(entryPoint?.rawValue)
  }

  public func requestDidSucceed(_ placement: TJPlacement) {
    ChannelManager.shared.invokeChannelMethod(channelName, "onRequestSuccess", arguments: placement.placementName)
  }

  public func requestDidFail(_ placement: TJPlacement, error: Error?) {
    ChannelManager.shared.invokeChannelMethod(channelName,
      "onRequestFailure",
      arguments: ["placementName": placement.placementName, "error": error?.localizedDescription])
  }

  public func contentIsReady(_ placement: TJPlacement) {
    ChannelManager.shared.invokeChannelMethod(channelName, "onContentReady", arguments: placement.placementName)
  }

  public func contentDidAppear(_ placement: TJPlacement) {
    ChannelManager.shared.invokeChannelMethod(channelName, "onContentShow", arguments: placement.placementName)
  }

  public func contentDidDisappear(_ placement: TJPlacement) {
    ChannelManager.shared.invokeChannelMethod(channelName, "onContentDismiss", arguments: placement.placementName)
  }
}
