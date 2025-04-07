import 'package:flutter/material.dart';
import 'dart:developer';
import 'globals.dart' as globals;
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'dart:io';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  final TextEditingController _userIdController = TextEditingController();

  final TextEditingController _userLevelController = TextEditingController();

  final TextEditingController _maxUserLevelController = TextEditingController();

  final TextEditingController _userTagController = TextEditingController();

  final TextEditingController _usPrivacyController = TextEditingController();

  TJSegment? _selectedSegment;

  TJStatus? _selectedGPDR;

  TJStatus? _selectedConsent;

  TJStatus? _selectedBelowAge;

  String _statusMessage = '';

  bool _isOptOutAdIdChecked = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void initPlatformState() async {
    var userId = await Tapjoy.getUserID();
    log('getUserID: $userId.');
    _userIdController.text = userId ?? "";

    var userLevel = await Tapjoy.getUserLevel();
    if (userLevel != null) {
      log('getUserLevel: $userLevel.');
      setState(() {
        _userLevelController.text = userLevel.toString();
      });
    }

    var maxUserLevel = await Tapjoy.getMaxLevel();
    if (maxUserLevel != null) {
      log('getMaxLevel: $maxUserLevel.');
      setState(() {
        _maxUserLevelController.text = maxUserLevel.toString();
      });
    }

    TJSegment? userSegment = await Tapjoy.getUserSegment() ?? TJSegment.unknown;
    setState(() {
      _selectedSegment = userSegment;
    });
    log('getUserSegment: ${userSegment.name}.');

    TJStatus? gdpr = await Tapjoy.getPrivacyPolicy().getSubjectToGDPR() ??
        TJStatus.unknownStatus;
    log('tjPrivacyPolicy.getSubjectToGDPR: ${gdpr.toString()}');
    setState(() {
      _selectedGPDR = gdpr;
    });

    TJStatus? consent = await Tapjoy.getPrivacyPolicy().getUserConsent() ??
        TJStatus.unknownStatus;
    log('tjPrivacyPolicy.getUserConsent: ${consent.toString()}');
    setState(() {
      _selectedConsent = consent;
    });

    TJStatus? belowAge = await Tapjoy.getPrivacyPolicy().getBelowConsentAge() ??
        TJStatus.unknownStatus;
    log('tjPrivacyPolicy.getBelowConsentAge: ${belowAge.toString()}');
    setState(() {
      _selectedBelowAge = belowAge;
    });

    String? usPrivacy = await Tapjoy.getPrivacyPolicy().getUSPrivacy();
    log('tjPrivacyPolicy.getUSPrivacy: ${usPrivacy.toString()}');
    if (usPrivacy != null) {
      setState(() {
        _usPrivacyController.text = usPrivacy;
      });
    }

    if(Platform.isAndroid) {
      bool isOptOutAdId = await getOptOutAdId();
      setState(() {
        _isOptOutAdIdChecked = isOptOutAdId;
      });
    }
  }

  void setUserInfo() {
    Tapjoy.setUserID(
        userId: _userIdController.text,
        onSetUserIDSuccess: () => setState(() {
              log('onSetUserIDSuccess');
              _statusMessage = 'User ID Set: ${_userIdController.text}';
            }),
        onSetUserIDFailure: (error) => setState(() {
              log('onSetUserIDFailure: $error');
              _statusMessage = 'User ID Failed: $error';
            }));

    int userLevel = int.tryParse(_userLevelController.text) ?? -1;
    Tapjoy.setUserLevel(userLevel);
    log('setUserLevel: $userLevel');

    int maxUserLevel = int.tryParse(_maxUserLevelController.text) ?? -1;
    Tapjoy.setMaxLevel(maxUserLevel);
    log('setMaxLevel: $maxUserLevel');
  }

  void clearUserInfo() {
    Tapjoy.setUserID(
        userId: null,
        onSetUserIDSuccess: () => '',
        onSetUserIDFailure: (error) => '');
    Tapjoy.setUserLevel(-1);
    Tapjoy.setMaxLevel(-1);
    _userIdController.text = '';
    _userLevelController.text = '';
    _maxUserLevelController.text = '';

    log('Inputs cleared');
    setState(() {
      _statusMessage = 'Inputs Cleared';
    });
  }

  void setUserSegment() {
    if (_selectedSegment == null) {
      return;
    }
    Tapjoy.setUserSegment(_selectedSegment!);
    log('setUserSegment: ${_selectedSegment?.name}.');
  }

  void setSubjectToGDPR() {
    if (_selectedGPDR == null) {
      return;
    }
    Tapjoy.getPrivacyPolicy().setSubjectToGDPR(_selectedGPDR!);
    log('setSubjectToGDPR: ${_selectedGPDR?.name}.');
  }

  void setUserConsent() {
    if (_selectedConsent == null) {
      return;
    }
    Tapjoy.getPrivacyPolicy().setUserConsent(_selectedConsent!);
    log('setUserConsent: ${_selectedConsent?.name}.');
  }

  void setBelowConsentAge() {
    if (_selectedBelowAge == null) {
      return;
    }
    Tapjoy.getPrivacyPolicy().setBelowConsentAge(_selectedBelowAge!);
    log('setBelowConsentAge: ${_selectedBelowAge?.name}.');
  }

  void setUSPrivacy() {
    Tapjoy.getPrivacyPolicy().setUSPrivacy(_usPrivacyController.text);
    log('setUSPrivacy: ${_usPrivacyController.text}.');
    setState(() {
      _statusMessage = _usPrivacyController.text.isEmpty
          ? 'Removed US Privacy Value.'
          : 'Saved US Privacy Value.';
    });
  }

  void setUserTags() {
    var userTags = _userTagController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (userTags.isNotEmpty) {
      Tapjoy.setUserTags(userTags);
      setState(() {
        _userTagController.text = '';
      });
      log('setUserTags: ${userTags.join(', ')}.');
    }
  }

  void clearUserTags() {
    Tapjoy.clearUserTags();
    setState(() {
      _userTagController.text = '';
    });
    log('clearUserTags');
  }

  void addUserTag() {
    var userTag = _userTagController.text.trim();
    if (userTag.isNotEmpty) {
      Tapjoy.addUserTag(userTag);
      setState(() {
        _userTagController.text = '';
      });
      log('setUserTag: $userTag.');
    }
  }

  void removeUserTag() {
    var userTag = _userTagController.text.trim();
    if (userTag.isNotEmpty) {
      Tapjoy.removeUserTag(userTag);
      setState(() {
        _userTagController.text = '';
      });
      log('removeUserTag: $userTag.');
    }
  }

  Future<void> setOptOutAdId(bool optOut) async {
    Tapjoy.optOutAdvertisingID(optOut);
    setState(() {
      _isOptOutAdIdChecked = optOut;
    });
  }

  Future<bool> getOptOutAdId() async {
    return await Tapjoy.getOptOutAdvertisingID() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle compactButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
    );
    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
              child: Column(
            children: [
              Text(_statusMessage),
              Row(
                children: [
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'User ID'),
                        )),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: TextField(
                          controller: _userLevelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'User Level'),
                        )),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: TextField(
                          controller: _maxUserLevelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Max User Level'),
                        )),
                  ),
                ],
              ),
              Row(
                children: [
                  const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text("User Segment:")),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<TJSegment>(
                      value: _selectedSegment,
                      isExpanded: true,
                      items: TJSegment.values.map((TJSegment segment) {
                        return DropdownMenuItem<TJSegment>(
                          value: segment,
                          child: Text(segment.name),
                        );
                      }).toList(),
                      onChanged: (TJSegment? newValue) {
                        setState(() {
                          _selectedSegment = newValue;
                          setUserSegment();
                        });
                      },
                    ),
                  )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                            () => setUserInfo(),
                        child: const Text('Set'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                             () => clearUserInfo(),
                        child: const Text('Clear'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: TextField(
                          controller: _userTagController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'User Tag(s)'),
                        )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                            () => setUserTags(),
                        child: const Text('Set Tags'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                            () => addUserTag(),
                        child: const Text('Add'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                          () => removeUserTag(),
                        child: const Text('Remove'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElevatedButton(
                        style: compactButtonStyle,
                        onPressed:
                          () => clearUserTags(),
                        child: const Text('Clear'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text("Subject to GDPR:")),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<TJStatus>(
                      value: _selectedGPDR,
                      isExpanded: true,
                      items: TJStatus.values.map((TJStatus status) {
                        return DropdownMenuItem<TJStatus>(
                          value: status,
                          child: Text(status.name),
                        );
                      }).toList(),
                      onChanged: (TJStatus? newValue) {
                        setState(() {
                          _selectedGPDR = newValue;
                          setSubjectToGDPR();
                        });
                      },
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text("User Consent:")),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<TJStatus>(
                      value: _selectedConsent,
                      isExpanded: true,
                      items: TJStatus.values.map((TJStatus status) {
                        return DropdownMenuItem<TJStatus>(
                          value: status,
                          child: Text(status.name),
                        );
                      }).toList(),
                      onChanged: (TJStatus? newValue) {
                        setState(() {
                          _selectedConsent = newValue;
                          setUserConsent();
                        });
                      },
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text("Below Consent Age:")),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<TJStatus>(
                      value: _selectedBelowAge,
                      isExpanded: true,
                      items: TJStatus.values.map((TJStatus status) {
                        return DropdownMenuItem<TJStatus>(
                          value: status,
                          child: Text(status.name),
                        );
                      }).toList(),
                      onChanged: (TJStatus? newValue) {
                        setState(() {
                          _selectedBelowAge = newValue;
                          setBelowConsentAge();
                        });
                      },
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 20),
                        child: TextField(
                          controller: _usPrivacyController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'US Privacy'),
                        )),
                  ),
                  ElevatedButton(
                    style: compactButtonStyle,
                    onPressed:
                        () => setUSPrivacy(),
                    child: const Text('Set'),
                  ),
                ],
              ),
              if (Platform.isAndroid)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                        padding: EdgeInsets.only(left: 4, top: 8),
                        child: Text("Opt Out Advertising ID")),
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Checkbox(
                          value: _isOptOutAdIdChecked,
                          onChanged: (bool? value) {
                            setOptOutAdId(value!);
                          },
                        )),
                  ],
                )
            ],
          )),
        ),
      ]),
    );
  }
}
