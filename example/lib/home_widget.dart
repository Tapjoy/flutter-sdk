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

  final TextEditingController _managedCurrencyController = TextEditingController(text: '10');
  final TextEditingController _placementNameController = TextEditingController(text: 'offerwall_unit');
  final TextEditingController _currencyIdController = TextEditingController();
  final TextEditingController _currencyBalanceController = TextEditingController();
  final TextEditingController _currencyRequiredAmountController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController(text: '0.99');
  final TextEditingController _purchaseCurrencyController = TextEditingController(text: 'USD');

  bool _offerwallReadyToShow = false;
  TJEntryPoint _selectedEntryPoint = TJEntryPoint.entryPointUnknown;
  TJLoggingLevel _loggingLevel = TJLoggingLevel.error;
  String _statusMessage = '';

  void setAppConnected(bool connected) {
    setState(() {
      globals.isConnected = connected;
    });
  }

  void setOfferwallReadyToShow(bool? active) {
    setState(() {
      _offerwallReadyToShow = active ?? false;
    });
  }

  void setStatusMessage(String message) {
    log(message);
    setState(() {
      _statusMessage = message;
    });
  }

  void setLoggingLevel(TJLoggingLevel level) {
    setState(() {
      _loggingLevel = level;
    });
  }

  void setEntryPoint(TJEntryPoint entryPoint) {
    setState(() {
      _selectedEntryPoint = entryPoint;
    });
  }

  @override
  void initState() {
    super.initState();
    populateUi();
    checkAutoConnect();
  }

  void populateUi() async {
    updateOfferwallReadyToShow();
    setAppConnected(globals.isConnected);
    setStatusMessage(globals.isConnected ? 'Tapjoy SDK Connected' : 'Click Connect to Start');
    setLoggingLevel(await Tapjoy.getLoggingLevel());
  }

  void updateOfferwallReadyToShow() async {
    setOfferwallReadyToShow(await globals.loadedPlacement?.isContentReady());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> trackingTransparencyRequest() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    log('Preparing SDK setting');
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
    if (isAutoConnect) initSDK();
  }

  Future<void> initSDK() async {
    log('initSDK()');
    if (globals.isConnected) {
      log('SDK already connected');
      return;
    }
    if (Platform.isIOS) {
      trackingTransparencyRequest();
    }
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      final Map<String, dynamic> optionFlags = { };
      Tapjoy.setLoggingLevel(TJLoggingLevel.debug);
      // optionFlags[TapjoyConnectFlags.user_id] = "[USER_ID]";
      // optionFlags[TapjoyConnectFlags.logging_level] = TJLoggingLevel.debug.index;
      Tapjoy.setCustomParameter("custom_parameter");
      await Tapjoy.connect(
        sdkKey: await getSdkKey(),
        options: optionFlags,
        onConnectSuccess: () async {
          setStatusMessage('Tapjoy SDK connected');
          setAppConnected(true);
          setLoggingLevel(await Tapjoy.getLoggingLevel());
        },
        onConnectFailure: (int code, String? error) async {
          setStatusMessage(
              'Tapjoy connect failed: $error Error code: $code');
          setAppConnected(false);
        },
        onConnectWarning: (int code, String? warning) async {
          setStatusMessage('Tapjoy connect warning: $warning Code: $code');
        },
      );
    } on PlatformException {
      setStatusMessage('Failed to get platform version.');
    }
  }

  Future<void> loadOfferwallPlacement() async {
    setStatusMessage(
        'Requesting content for placement: ${_placementNameController.text}');
    if (await Tapjoy.getCustomParameter() != null) {
      setStatusMessage(
          'Custom parameter: ${await Tapjoy.getCustomParameter()}');
    }
    globals.loadedPlacement = await Tapjoy.getPlacement(
        placementName: _placementNameController.text,
        onRequestSuccess: (placement) async {
          var isContentAvailable = await placement.isContentAvailable();
          setStatusMessage(
              'onRequestSuccess for placement: ${placement.placementName}, isContentAvailable:  $isContentAvailable');
              updateOfferwallReadyToShow();
        },
        onRequestFailure: (placement, error) {
          setStatusMessage(
              'onRequestFailure for placement: ${placement.placementName}, $error');
          globals.loadedPlacement = null;
        },
        onContentReady: (placement) {
          setStatusMessage(
              'onContentReady for placement: ${placement.placementName}');
          updateOfferwallReadyToShow();
        },
        onContentShow: (placement) {
          setStatusMessage(
              'onContentShow for placement: ${placement.placementName}');
        },
        onContentDismiss: (placement) {
          setStatusMessage(
              'onContentDismiss for placement: ${placement.placementName}');
          globals.loadedPlacement = null;
          updateOfferwallReadyToShow();
        });
    if (_selectedEntryPoint != TJEntryPoint.entryPointUnknown) {
      globals.loadedPlacement?.setEntryPoint(_selectedEntryPoint);
      log('setEntryPoint: ${_selectedEntryPoint.name}.');
    }

    if (_currencyIdController.text.isNotEmpty) {
      if (_currencyBalanceController.text.isNotEmpty) {
        final balance = int.tryParse(_currencyBalanceController.text);
        final currencyId = _currencyIdController.text;
        if (balance != null) {
          globals.loadedPlacement?.setCurrencyBalance(
              currencyBalance: balance,
              currencyId: currencyId,
              onSuccess: (placement) {
                log('setCurrencyBalance success: $balance, $currencyId');
              },
              onFailure: (placement, error) {
                log('setCurrencyBalance error: $error');
              });
        }
      }

      if (_currencyRequiredAmountController.text.isNotEmpty) {
        final requiredAmount =
            int.tryParse(_currencyRequiredAmountController.text);
        final currencyId = _currencyIdController.text;
        if (requiredAmount != null) {
          globals.loadedPlacement?.setRequiredAmount(
              requiredAmount: requiredAmount,
              currencyId: currencyId,
              onSuccess: (placement) {
                log('setRequiredAmount success: $requiredAmount, $currencyId');
              },
              onFailure: (placement, error) {
                log('setRequiredAmount error: $error');
              });
        }
      }
    }

    globals.loadedPlacement?.requestContent();
  }

  Future<void> getCurrencyBalance() async {
    await Tapjoy.getCurrencyBalance(
        onGetCurrencyBalanceSuccess: (currencyName, balance) {
      setStatusMessage('$currencyName: $balance');
    }, onGetCurrencyBalanceFailure: (error) {
      setStatusMessage('getCurrencyBalance error: $error');
    });
  }

  Future<void> spendCurrency() async {
    var amount = int.parse(_managedCurrencyController.text);
    await Tapjoy.spendCurrency(
        amount: amount,
        onSpendCurrencySuccess: (currencyName, balance) {
          setStatusMessage('$currencyName: $balance');
        },
        onSpendCurrencyFailure: (error) {
          setStatusMessage('spendCurrency error: $error');
        });
  }

  Future<void> awardCurrency() async {
    var amount = int.parse(_managedCurrencyController.text);
    await Tapjoy.awardCurrency(
        amount: amount,
        onAwardCurrencySuccess: (currencyName, balance) {
          setStatusMessage('$currencyName: $balance');
        },
        onAwardCurrencyFailure: (error) {
          setStatusMessage('awardCurrency error: $error');
        });
  }

  Future<void> purchase() async {
    final price = double.tryParse(_purchasePriceController.text) ?? 0;
    final currency = _purchaseCurrencyController.text;
    setStatusMessage(
        'Sent track purchase: ${formatNumber(price)} $currency');
    await Tapjoy.trackPurchase(currency, price);
  }

  String formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    final ButtonStyle segmentedControlButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Column(children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                        child: Text(_statusMessage)),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 30, right: 30),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: globals.isConnected ? null : () => initSDK(),
                              child: Text(
                                  globals.isConnected ? 'Connected' : 'Connect SDK'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        controller: _managedCurrencyController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Managed Currency',
                          hintText: 'Currency amount',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
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
                    Row(children: <Widget>[
                      Flexible(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: TextField(
                              controller: _placementNameController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Placement Name',
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  hintStyle: TextStyle(color: Colors.grey)),
                            )),
                      )
                    ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: compactButtonStyle,
                          onPressed: globals.isConnected && !_offerwallReadyToShow
                              ? () => loadOfferwallPlacement()
                              : null,
                          child: const Text('Request'),
                        ),
                        ElevatedButton(
                          style: compactButtonStyle,
                          onPressed: globals.isConnected && _offerwallReadyToShow
                              ? () {
                            log('showContent ${globals.loadedPlacement?.placementName}');
                            globals.loadedPlacement?.showContent();
                          }
                              : null,
                          child: const Text('Show'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              child: DropdownButton<TJEntryPoint>(
                                value: _selectedEntryPoint,
                                isExpanded: true,
                                items: TJEntryPoint.values.map((TJEntryPoint entryPoint) {
                                  return DropdownMenuItem<TJEntryPoint>(
                                    value: entryPoint,
                                    child: entryPoint == TJEntryPoint.entryPointUnknown
                                        ? const Text("Select Entry Point")
                                        : Text(entryPoint.name),
                                  );
                                }).toList(),
                                onChanged: (TJEntryPoint? newValue) {
                                  if (newValue != null) {
                                    setEntryPoint(newValue);
                                  }
                                },
                              ),
                            )),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Currency",
                            style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: TextField(
                        controller: _currencyIdController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Identifier',
                          hintText: 'Currency ID',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: TextField(
                        controller: _currencyBalanceController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Balance',
                          hintText: 'Self-managed only',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: TextField(
                        controller: _currencyRequiredAmountController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Required Amount',
                          hintText: 'Required amount of currency',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Purchase",
                            style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 8, bottom: 8),
                          child: TextField(
                            controller: _purchasePriceController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Price',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 8, right: 20, bottom: 8),
                          child: TextField(
                            controller: _purchaseCurrencyController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Code',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    ElevatedButton(
                      style: compactButtonStyle,
                      onPressed: globals.isConnected ? () => purchase() : null,
                      child: const SizedBox(
                        width: 260,
                        child: Center(
                          child: Text('Purchase'),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Padding(
                            padding: EdgeInsets.only(top: 10, left: 10, right: 4),
                            child: Text("Logging level")),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 10),
                          child: SegmentedButton<TJLoggingLevel>(segments: const <ButtonSegment<TJLoggingLevel>>[
                              ButtonSegment<TJLoggingLevel>(
                                value: TJLoggingLevel.error,
                                label: Text('Error'),
                              ),
                              ButtonSegment<TJLoggingLevel>(
                                value: TJLoggingLevel.warning,
                                label: Text('Warning'),
                              ),
                              ButtonSegment<TJLoggingLevel>(
                                value: TJLoggingLevel.info,
                                label: Text('Info'),
                              ),
                              ButtonSegment<TJLoggingLevel>(
                                value: TJLoggingLevel.debug,
                                label: Text('Debug'),
                              ),
                            ],
                            selected: {_loggingLevel},
                            showSelectedIcon: false,
                            style: segmentedControlButtonStyle,
                            onSelectionChanged: (Set newSelection) async {
                              var originalLoggingLevel = await Tapjoy.getLoggingLevel();
                              setLoggingLevel(newSelection.first);
                              Tapjoy.setLoggingLevel(_loggingLevel);
                              var currentLoggingLevel = await Tapjoy.getLoggingLevel();
                              if (currentLoggingLevel != _loggingLevel) {
                                setLoggingLevel(originalLoggingLevel);
                              }
                            },
                          ),
                        )),
                      ],
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 10, top: 20, bottom: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Version: ${Tapjoy.getPluginVersion()}"),
                      ),
                    )
                  ],
                )),
          ),
        ]),
      )
    );
  }
}
