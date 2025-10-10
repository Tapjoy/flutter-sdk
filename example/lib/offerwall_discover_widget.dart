import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

class OfferwallDiscoverWidget extends StatefulWidget {
  const OfferwallDiscoverWidget({super.key});

  @override
  State<OfferwallDiscoverWidget> createState() =>
      _OfferwallDiscoverWidgetState();
}

class _OfferwallDiscoverWidgetState extends State<OfferwallDiscoverWidget> {
  String _statusMessage = 'Status Message';
  Size size = PlatformDispatcher.instance.views.first.physicalSize;
  late double _width;
  double _height = 262.00;
  bool _isWidthManuallySet = false;

  late final TextEditingController _widthTextController =
      TextEditingController();
  final TextEditingController _heightTextController =
      TextEditingController(text: '262');
  final TextEditingController _offerwallDiscoverPlacementTextController =
      TextEditingController(text: 'offerwall_discover');
  late StreamSubscription _tapjoySubscription;
  final TJOfferwallDiscover _offerwallDiscover = TJOfferwallDiscover();
  var _showOfferwallDiscover = false;

  @override
  void initState() {
    super.initState();
    _tapjoySubscription = Tapjoy.listen(
      onEvent: _handleOWDEvent,
      onError: _handleOWDError,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isWidthManuallySet) {
        setState(() {
          _width = MediaQuery.of(context).size.width.floorToDouble();
          _widthTextController.text = "${_width.truncate()}";
        });
      }
    });
  }

  void _handleOWDEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case TJOWDRequestDidSucceedForViewListener:
        _updateStatusMessage(
            "$TJOWDRequestDidSucceedForViewListener Event: ${event['value']}");
        break;
      case TJOWDContentIsReadyForViewListener:
        _updateStatusMessage(
            "$TJOWDContentIsReadyForViewListener Event: ${event['value']}");
        setState(() => _showOfferwallDiscover = true);
        break;
      default:
        _updateStatusMessage(event['value']);
        break;
    }
  }

  void _handleOWDError(Object error) {
    if (error is PlatformException) {
      switch (error.message) {
        case TJOWDContentErrorForViewListener:
          _updateStatusMessage(
              "$TJOWDContentErrorForViewListener: ${error.details}");
          break;
        case TJOWDRequestDidFailForViewListener:
          _updateStatusMessage(
              "$TJOWDRequestDidFailForViewListener: ${error.details}");
          break;
      }
    }
  }

  void _updateStatusMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  @override
  void dispose() {
    _tapjoySubscription.cancel();
    super.dispose();
  }

  Future<void> loadOfferwallDiscover() async {
    resizeView();
    await _offerwallDiscover
        .requestOWDContent(_offerwallDiscoverPlacementTextController.text);
    setState(() {});
  }

  Future<void> clearOfferwallDiscover() async {
    _showOfferwallDiscover = false;
    await _offerwallDiscover.clearOWDContent();
    setState(() {});
  }

  void resizeView() {
    final double newWidth = double.tryParse(_widthTextController.text) ?? 0.0;
    final double newHeight = double.tryParse(_heightTextController.text) ?? 0.0;
    final double screenWidth =
        MediaQuery.of(context).size.width.floorToDouble();
    setState(() {
      _width = newWidth;
      _height = newHeight;
      _isWidthManuallySet = newWidth != screenWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (!_isWidthManuallySet) {
            final newWidth = MediaQuery.of(context).size.width.floorToDouble();
            if (_width != newWidth) {
              _width = newWidth;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _widthTextController.text = "${_width.truncate()}";
              });
            }
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(_statusMessage),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _widthTextController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Width',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          _isWidthManuallySet = true;
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _heightTextController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Height',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed: resizeView,
                        child: const Text('Resize'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  textInputAction: TextInputAction.newline,
                  controller: _offerwallDiscoverPlacementTextController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Placement Name',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: loadOfferwallDiscover,
                    child: const Text('Request'),
                  ),
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: clearOfferwallDiscover,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  color: Colors.grey,
                  width: _width,
                  height: _height,
                  child: _showOfferwallDiscover
                      ? const TJOfferwallDiscoverViewWidget()
                      : const Center(child: Text("Offerwall Discover")),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
