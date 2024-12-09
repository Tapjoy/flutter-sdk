import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigWidget extends StatefulWidget {
  const ConfigWidget({super.key});

  @override
  State<ConfigWidget> createState() => _ConfigWidgetState();
}

class _ConfigWidgetState extends State<ConfigWidget> {
  TextEditingController _sdkKeyController = TextEditingController();

  final String _statusMessage = 'Restart the app to Connect with the new key';

  bool _isAutoConnect = false;

  @override
  void initState() {
    super.initState();
    getLastSdkKey();
    checkAutoConnect();
  }

  Future<List<String>> getSdkList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? sdkKeys = prefs.getStringList('sdk_keys');
    if (sdkKeys == null) {
      String key = Platform.isAndroid
          ? 'u6SfEbh_TA-WMiGqgQ3W8QECyiQIURFEeKm0zbOggubusy-o5ZfXp33sTXaD'
          : 'E7CuaoUWRAWdz_5OUmSGsgEBXHdOwPa8de7p4aseeYP01mecluf-GfNgtXlF';
      addSdkKey(key);
      List<String> newSdkList = List.empty(growable: true);
      newSdkList.add(key);
      return newSdkList;
    }
    return sdkKeys;
  }

  Future<void> getLastSdkKey() async {
    List<String> sdkList = await getSdkList();
    _sdkKeyController.text = sdkList.last;
  }

  Future<void> addSdkKey(String sdkKey) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> sdkKeys =
        prefs.getStringList('sdk_keys') ?? List.empty(growable: true);
    if (!sdkKeys.contains(sdkKey)) {
      sdkKeys.add(sdkKey);
    } else {
      sdkKeys.remove(sdkKey);
      sdkKeys.add(sdkKey);
    }
    prefs.setStringList('sdk_keys', sdkKeys);
  }

  Future<void> checkAutoConnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAutoConnect = prefs.getBool('auto_connect') ?? true;
    setState(() {
      _isAutoConnect = isAutoConnect;
    });
  }

  Future<void> setAutoConnect(bool isAuto) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('auto_connect', isAuto);
    setState(() {
      _isAutoConnect = isAuto;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      padding: const EdgeInsets.only(
                          left: 10.0, right: 10.0, bottom: 10.0),
                      child: Text(_statusMessage)),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Checkbox(
                              value: _isAutoConnect,
                              onChanged: (bool? value) {
                                setAutoConnect(value ?? true);
                              }),
                          const Text('Auto Connect')
                        ],
                      )),
                  Autocomplete<String>(fieldViewBuilder: (BuildContext context,
                      TextEditingController sdkEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    _sdkKeyController = sdkEditingController;
                    return TextField(
                      controller: sdkEditingController,
                      focusNode: fieldFocusNode,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Enter SDK Key"),
                    );
                  }, optionsBuilder: (TextEditingValue textEditingValue) async {
                    return await getSdkList();
                  }, onSelected: (String selection) {
                    addSdkKey(selection);
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          style: compactButtonStyle,
                          onPressed: () => addSdkKey(_sdkKeyController.text),
                          child: const Text('Add'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            style: compactButtonStyle,
                            onPressed: () => _sdkKeyController.clear(),
                            child: const Text('Clear'),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
