import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';


class OfferwallDiscoverWidget extends StatefulWidget {
  const OfferwallDiscoverWidget({super.key});

  @override
  State<OfferwallDiscoverWidget> createState() => _OfferwallDiscoverWidgetState();
}

class _OfferwallDiscoverWidgetState extends State<OfferwallDiscoverWidget> {

  String _statusMessage = 'Status Message';
  Size size = PlatformDispatcher.instance.views.first.physicalSize;
  late double _width;
  double _height = 262.00;
  late final TextEditingController _widthTextController = TextEditingController();
  final TextEditingController _heightTextController = TextEditingController(text: '262');
  final TextEditingController _offerwallDiscoverPlacementTextController = TextEditingController(text: 'offerwall_discover');
  late StreamSubscription _tapjoySubscription;
  final TJOfferwallDiscover _offerwallDiscover = TJOfferwallDiscover();
  Orientation? _currentOrientation;
  var _showOfferwallDiscover = false;

  @override
  void initState() {
    super.initState();
    _tapjoySubscription = Tapjoy.listen(
      onEvent: _handleOWDEvent,
      onError: _handleOWDError,
    );
    _width = size.width;
    _widthTextController.text = "${_width.truncate()}";
  }

  void _handleOWDEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case TJOWDRequestDidSucceedForViewListener:
        _updateStatusMessage("$TJOWDRequestDidSucceedForViewListener Event: ${event['value']}");
        break;
      case TJOWDContentIsReadyForViewListener:
        _updateStatusMessage("$TJOWDContentIsReadyForViewListener Event: ${event['value']}");
        setState(() => _showOfferwallDiscover = true);
        break;
      default:
        _updateStatusMessage(event['value']);
        break;
    }
  }

  void _handleOWDError(Object error) {
    if (error is PlatformException) {
      switch (error.details) {
        case TJOWDContentErrorForViewListener:
          _updateStatusMessage("$TJOWDContentErrorForViewListener : ${error.message}");
          break;
        case TJOWDRequestDidFailForViewListener:
          _updateStatusMessage("$TJOWDRequestDidFailForViewListener : ${error.message}");
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
    _width = double.parse(_widthTextController.text);
    _height = double.parse(_heightTextController.text);
    await _offerwallDiscover.requestOWDContent(_offerwallDiscoverPlacementTextController.text);
    setState(() {});
  }

  Future<void> clearOfferwallDiscover() async {
    _showOfferwallDiscover = false;
    await _offerwallDiscover.clearOWDContent();
    setState(() {});
  }

  void resizeView() {
    _width = double.parse(_widthTextController.text);
    _height = double.parse(_heightTextController.text);
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentOrientation != MediaQuery.of(context).orientation) {
    _updateWidth();
    }
  }

  void _updateWidth() {
    setState(() {
      _width = (MediaQuery.of(context).size.width).floorToDouble();
      _widthTextController.text = "${_width.truncate()}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    _currentOrientation = MediaQuery.of(context).orientation;
    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(child: SingleChildScrollView (
            child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Text(_statusMessage)),
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:TextField(
                    controller: _widthTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Width',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ]
                  ),
                  ),
                  ),
                  Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:TextField(
                    controller: _heightTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Height',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ]
                  ),
                  ),
                  ),
              Flexible(child: Padding(
                padding: const EdgeInsets.all(8.0) ,
                child: ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: () => resizeView(),
                    child: const Text('Resize')
                ),
              ))
            ],),
            Row(
              children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    textInputAction: TextInputAction.newline,
                    controller: _offerwallDiscoverPlacementTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Placement Name',
                    )
                  ))
              ,)
            ],),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: compactButtonStyle,
                onPressed: () => loadOfferwallDiscover(),
                child: const Text('Request')
                ),
              ElevatedButton(
                style: compactButtonStyle,
                onPressed: () => clearOfferwallDiscover(),
                child: const Text('Clear')
                ),
            ],
          ),
      Container(
        color: Colors.grey,
        width: _width,
        height: _height,
        child:  _showOfferwallDiscover
                    ? const TJOfferwallDiscoverViewWidget()
                    : const Center(child: Text("Offerwall Discover")),
      )]
            )
        ))
        ],),
    );
  }
}