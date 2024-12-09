import 'models.dart';
import '../parsers/outgoing_value_parser.dart';
import '../tapjoy_channel_manager.dart';

class TJPlacement {

  /// TJplacement repository
  static final _placementMap = <String, TJPlacement>{};
  static const channelName = 'tapjoy_offerwall';

  final String placementName;

  TJPlacementOnRequestSuccessListener? onRequestSuccess;
  TJPlacementOnRequestFailureListener? onRequestFailure;
  TJPlacementOnContentReadyListener? onContentReady;
  TJPlacementOnContentShowListener? onContentShow;
  TJPlacementOnContentDismissListener? onContentDismiss;

  TJPlacement._(this.placementName);

  static Future<TJPlacement> getPlacement({required String placementName, 
    TJPlacementOnRequestSuccessListener? onRequestSuccess, 
    TJPlacementOnRequestFailureListener? onRequestFailure, 
    TJPlacementOnContentReadyListener? onContentReady, 
    TJPlacementOnContentShowListener? onContentShow, 
    TJPlacementOnContentDismissListener? onContentDismiss}) async {
      
    if(TJPlacement._placementMap[placementName] == null){
      TJPlacement._placementMap[placementName] = TJPlacement._(placementName);
    }
    TJPlacement placement = TJPlacement._placementMap[placementName]!;
    placement.onRequestSuccess = onRequestSuccess;
    placement.onRequestFailure = onRequestFailure;
    placement.onContentReady = onContentReady;
    placement.onContentShow = onContentShow;
    placement.onContentDismiss = onContentDismiss;

    final args = OutgoingValueParser.getPlacement(placementName: placementName);

    await TapjoyChannelManager.getChannel(channelName).invokeMethod<void>('getPlacement', args);

    return placement;
  }

  static TJPlacement? findPlacement(String placementName){
    return _placementMap[placementName];
  }

  /// Sends the placement request to the server
  ///
  /// Native SDK Reference
  /// - Android: requestContent
  /// -     iOS: requestContent
  Future<void> requestContent() async {
    final args = OutgoingValueParser.requestContent(placement: this);

    return await TapjoyChannelManager.getChannel(channelName).invokeMethod('requestContent', args);
  }

  /// Sends the placement request to the server
  ///
  /// Native SDK Reference
  /// - Android: showContent
  /// -     iOS: showContent
  Future<void> showContent() async {
    final args = OutgoingValueParser.showContent(placement: this);

    return await TapjoyChannelManager.getChannel(channelName).invokeMethod('showContent', args);
  }

  /// Sends the placement request to the server
  ///
  /// Native SDK Reference
  /// - Android: isContentReady
  /// -     iOS: isContentReady
  Future<bool> isContentReady() async {
     final args = OutgoingValueParser.isContentReady(placement: this);

   return await TapjoyChannelManager.getChannel(channelName).invokeMethod('isContentReady', args);
  }

  /// Sends the placement request to the server
  ///
  /// Native SDK Reference
  /// - Android: isContentAvailable
  /// -     iOS: isContentAvailable
  Future<bool> isContentAvailable() async {
    final args = OutgoingValueParser.isContentAvailable(placement: this);

    return await TapjoyChannelManager.getChannel(channelName).invokeMethod('isContentAvailable', args);
  }

  /// Sets the entry point for this placement instance.
  ///
  /// Native SDK Reference
  /// - Android: setEntryPoint
  /// -     iOS: setEntryPoint
  Future<void> setEntryPoint(TJEntryPoint entryPoint){
    final args = OutgoingValueParser.setEntryPoint(placement: this, entryPoint: entryPoint);
    
    return TapjoyChannelManager.getChannel(channelName).invokeMethod<void>('setEntryPoint', args);
  }

  /// Gets the entry point for this placement instance.
  ///
  /// Native SDK Reference
  /// - Android: getEntryPoint
  /// -     iOS: getEntryPoint
  Future<TJEntryPoint?> getEntryPoint() async {
    final args = OutgoingValueParser.getEntryPoint(placement: this);
    final entryPointValue = await TapjoyChannelManager.getChannel(channelName).invokeMethod<int>('getEntryPoint', args);

    return entryPointValue == null? null: TJEntryPoint.values[entryPointValue];
  }


}