import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'target_coordinates_screen.dart';
import 'navigation_screen.dart'; // 导入导航页面

class Destination {
  String name;
  double latitude;
  double longitude;

  Destination({required this.name, required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

class DestinationsListScreen extends StatefulWidget {
  const DestinationsListScreen({super.key});

  @override
  State<DestinationsListScreen> createState() => _DestinationsListScreenState();
}

class _DestinationsListScreenState extends State<DestinationsListScreen> {
  List<Destination> _destinations = []; // 存储目的地列表

  @override
  void initState() {
    super.initState();
    _loadDestinations(); // 在 Widget 初始化时加载目的地列表
  }

  // 从 SharedPreferences 加载目的地列表
  Future<void> _loadDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    final destinationsJson = prefs.getStringList('destinations');
    if (destinationsJson != null) {
      setState(() {
        _destinations = destinationsJson
            .map((json) => Destination.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  // 将目的地列表保存到 SharedPreferences
  Future<void> _saveDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    final destinationsJson = _destinations.map((dest) => jsonEncode(dest.toJson())).toList();
    await prefs.setStringList('destinations', destinationsJson);
  }

  // 缓存导航目标到 SharedPreferences
  Future<void> _cacheNavigationTarget(double latitude, double longitude, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('navigation_target_latitude', latitude);
    await prefs.setDouble('navigation_target_longitude', longitude);
    await prefs.setString('navigation_target_name', name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目的地列表'),
      ),
      body: ListView.builder(
        itemCount: _destinations.length,
        itemBuilder: (context, index) {
          final destination = _destinations[index];

          return Dismissible(
            key: Key(destination.name + destination.latitude.toString() + destination.longitude.toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                final removedDestination = _destinations.removeAt(index);
                _saveDestinations();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${removedDestination.name} 已删除')),
                );
              });
            },
            child: ListTile(
              title: Text(destination.name),
              subtitle: Text('纬度: ${destination.latitude.toStringAsFixed(4)}, 经度: ${destination.longitude.toStringAsFixed(4)}'),
              onTap: () async {
                // 点击列表项后缓存导航目标并直接导航到导航页面
                await _cacheNavigationTarget(destination.latitude, destination.longitude, destination.name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NavigationScreen(
                      targetLatitude: destination.latitude,
                      targetLongitude: destination.longitude,
                      targetName: destination.name,
                    ),
                  ),
                );
              },
              onLongPress: () {
                _showEditDialog(index, destination);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TargetCoordinatesScreen()),
          );

          if (result != null && result is Map<String, dynamic> && result.containsKey('latitude') && result.containsKey('longitude')) {
            final double latitude = result['latitude'];
            final double longitude = result['longitude'];
            final String name = result['name'] ?? '目的地${_destinations.length + 1}';

            setState(() {
              _destinations.add(Destination(name: name, latitude: latitude, longitude: longitude));
              _saveDestinations();
            });
          }
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  // 显示编辑目的地名称的对话框
  Future<void> _showEditDialog(int index, Destination destination) async {
    TextEditingController nameController = TextEditingController(text: destination.name);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑名称'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: '输入新的名称'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                setState(() {
                  _destinations[index].name = nameController.text;
                  _saveDestinations();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}