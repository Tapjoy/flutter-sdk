import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:developer';
import 'globals.dart' as globals;
import 'package:flutter/services.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';


class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {

  final TextEditingController _placementNameController =
      TextEditingController(text: 'offerwall_unit');

  bool _offerwallReadyToShow = false;

  TJPlacement? _offerwallPlacement;

  TJEntryPoint _selectedEntryPoint = TJEntryPoint.entryPointUnknown;

  String _statusMessage = '';

  void setAppConnected(bool connected) {
    setState(() {
      globals.isConnected = connected;
    });
  }

  void offerwallReadyToShow(bool active) {
    setState(() {
      _offerwallReadyToShow = active;
    });
  }

  @override
  void initState() {
    super.initState();
    setAppConnected(globals.isConnected);
    _statusMessage =
        globals.isConnected ? 'Tapjoy SDK Connected' : 'Click Connect to Start';
    offerwallReadyToShow(false);
    checkAutoConnect();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> trackingTransparencyRequest() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    log('Preparing SDK setting');
    log('setDebugEnabled(true)');
    await Tapjoy.setDebugEnabled(true);
    log('isConnected: ${await Tapjoy.isConnected()}');
  }

  Future<String> getSdkKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? sdkKeys = prefs.getStringList('sdk_keys');
    if (sdkKeys == null) {
      String key = Platform.isAndroid
          ? 'u6SfEbh_TA-WMiGqgQ3W8QECyiQIURFEeKm0zbOggubusy-o5ZfXp33sTXaD'
          : 'E7CuaoUWRAWdz_5OUmSGsgEBXHdOwPa8de7p4aseeYP01mecluf-GfNgtXlF';
      return key;
    }
    return sdkKeys.last;
  }

  Future<void> checkAutoConnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isAutoConnect = prefs.getBool('auto_connect') ?? true;
    if(isAutoConnect) initSDK();
  }

  Future<void> initSDK() async {
    log('initSDK()');
    if(Platform.isIOS) {
      trackingTransparencyRequest();
    }
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      final Map<String, dynamic> optionFlags = {};
      // optionFlags[TapjoyConnectFlags.user_id] = "[USER_ID]";
      await Tapjoy.connect(
        sdkKey: await getSdkKey(),
        options: optionFlags,
        onConnectSuccess: () async {
          _updateStatusMessage('Tapjoy SDK connected');
          setAppConnected(true);
        },
        onConnectFailure: (int code, String? error) async {
          _updateStatusMessage('Tapjoy connect failed: $error Error code: $code');
          setAppConnected(false);
        },
        onConnectWarning: (int code, String? warning) async {
          _updateStatusMessage('Tapjoy connect warning: $warning Code: $code');
        },
      );
    } on PlatformException {
      _updateStatusMessage('Failed to get platform version.');
    }
  }

  Future<void> loadOfferwallPlacement() async {
    _updateStatusMessage('Requesting content for placement: ${_placementNameController.text}');

    _offerwallPlacement = await Tapjoy.getPlacement(
        placementName: _placementNameController.text,
        onRequestSuccess: (placement) async {
          var isContentAvailable = await placement.isContentAvailable();
          _updateStatusMessage('onRequestSuccess for placement: ${placement.placementName}, isContentAvailable:  $isContentAvailable');
        },
        onRequestFailure: (placement, error) {
          _updateStatusMessage('onRequestFailure for placement: ${placement.placementName}, $error');
        },
        onContentReady: (placement) {
          _updateStatusMessage('onContentReady for placement: ${placement.placementName}');
          offerwallReadyToShow(true);
        },
        onContentShow: (placement) {
          _updateStatusMessage('onContentShow for placement: ${placement.placementName}');
        },
        onContentDismiss: (placement) {
          _updateStatusMessage('onContentDismiss for placement: ${placement.placementName}');
          offerwallReadyToShow(false);
        });
    if(_selectedEntryPoint != TJEntryPoint.entryPointUnknown) {
      _offerwallPlacement?.setEntryPoint(_selectedEntryPoint);
      log('setEntryPoint: ${_selectedEntryPoint.name}.');
    }
    _offerwallPlacement?.requestContent();
  }

  Future<void> getCurrencyBalance() async {
    await Tapjoy.getCurrencyBalance(
        onGetCurrencyBalanceSuccess: (currencyName, balance) {
      _updateStatusMessage('$currencyName: $balance');
    }, onGetCurrencyBalanceFailure: (error) {
      _updateStatusMessage('getCurrencyBalance error: $error');
    });
  }

  Future<void> spendCurrency() async {
    await Tapjoy.spendCurrency(
        amount: 10,
        onSpendCurrencySuccess: (currencyName, balance) {
          _updateStatusMessage('$currencyName: $balance');
        },
        onSpendCurrencyFailure: (error) {
          _updateStatusMessage('spendCurrency error: $error');
        });
  }

  Future<void> awardCurrency() async {
    await Tapjoy.awardCurrency(
        amount: 20,
        onAwardCurrencySuccess: (currencyName, balance) {
          _updateStatusMessage('$currencyName: $balance');
        },
        onAwardCurrencyFailure: (error) {
          _updateStatusMessage('awardCurrency error: $error');
        });
  }

  void _updateStatusMessage(String message) {
    log(message);
    setState(() {
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
              child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, bottom: 10.0),
                  child: Text(_statusMessage)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 110.0, vertical: 10.0)),
                      onPressed: globals.isConnected ? null : () => initSDK(),
                      child: Text(
                          globals.isConnected ? 'Connected' : 'Connect SDK'),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: () => getCurrencyBalance(),
                    child: const Text('Get'),
                  ),
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: () => spendCurrency(),
                    child: const Text('Spend'),
                  ),
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: () => awardCurrency(),
                    child: const Text('Award'),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _placementNameController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Placement Name'),
                        )),
                  ),
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed: globals.isConnected
                        ? (_offerwallReadyToShow
                            ? () {
                                log('showContent ${_offerwallPlacement!.placementName}');
                                _offerwallPlacement!.showContent();
                                offerwallReadyToShow(false);
                              }
                            : () => loadOfferwallPlacement())
                        : null,
                    child: Text(_offerwallReadyToShow
                        ? 'Show Offerwall'
                        : 'Load Offerwall'),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<TJEntryPoint>(
                      value: _selectedEntryPoint,
                      isExpanded: true,
                      items: TJEntryPoint.values.map((TJEntryPoint entryPoint) {
                        return DropdownMenuItem<TJEntryPoint>(
                          value: entryPoint,
                          child: entryPoint == TJEntryPoint.entryPointUnknown ? Text("Select Entry Point") : Text(entryPoint.name),
                        );
                      }).toList(),
                      onChanged: (TJEntryPoint? newValue) {
                        setState(() {
                          _selectedEntryPoint = newValue!;
                        });
                      },
                    ),
                  )),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 20.0, bottom: 10.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text("Version: ${Tapjoy.getPluginVersion()}"),
                ),
              )
            ],
          )),
        ),
      ]),
    );
  }
}
