import 'package:flutter/material.dart';
import 'config_widget.dart';
import 'home_widget.dart';
import 'user_widget.dart';
import 'offerwall_discover_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    const HomeWidget(),
    const UserWidget(),
    const OfferwallDiscoverWidget(),
    const ConfigWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 15),
      body: SafeArea(
        child: _children[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'User',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark),
            label: 'Offerwall\nDiscover',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
