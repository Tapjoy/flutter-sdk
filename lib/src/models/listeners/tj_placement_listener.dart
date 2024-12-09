import '../tapjoy_placement.dart';


/// TJPlacement Listener

/// Invoked  when a content request for the given [placement] is successfully send to the server.
/// 
/// Native SDK Reference
/// - Android: onRequestSuccess
/// -     iOS: onRequestSuccess
typedef TJPlacementOnRequestSuccessListener = Function(TJPlacement placement);

/// Invoked  when a content request for the given [placement] is failed to send to and/or processed on the server with [error].
/// 
/// Native SDK Reference
/// - Android: onRequestFailure
/// -     iOS: onRequestFailure
typedef TJPlacementOnRequestFailureListener = Function(TJPlacement placement, String? error);

/// Invoked when a content for the given [placement] is ready to show.
///
/// Native SDK Reference
/// - Android: onContentReady
/// -     iOS: onContentReady
typedef TJPlacementOnContentReadyListener = Function(TJPlacement placement);

/// Invoked when a content for the given [placement] is showing.
///
/// Native SDK Reference
/// - Android: onContentShow
/// -     iOS: onContentShow
typedef TJPlacementOnContentShowListener = Function(TJPlacement placement);

/// Invoked when a content for the given [placement] is dismissed.
///
/// Native SDK Reference
/// - Android: onContentDismiss
/// -     iOS: onContentDismiss
typedef TJPlacementOnContentDismissListener = Function(TJPlacement placement);

