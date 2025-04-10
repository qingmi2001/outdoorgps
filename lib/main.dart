import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 shared_preferences

import 'target_coordinates_screen.dart';
import 'direction_info.dart';
import 'speed_info.dart';
import 'coordinates_info.dart';
import 'navigation_screen.dart';
import 'destinations_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '户外导航',
      theme: ThemeData(
        primarySwatch: Colors.green,
        hintColor: Colors.grey.shade400,
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
          titleTextStyle: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          headlineSmall: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyMedium: GoogleFonts.openSans(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodySmall: GoogleFonts.openSans(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ),
      home: const CompassScreen(),
    );
  }
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _heading; // 当前设备朝向
  List<double> _speedBuffer = []; // 速度缓冲队列
  int _speedBufferSize = 5; // 速度缓冲大小
  double _speed = 0.0; // 当前速度
  Position? _currentPosition; // 当前位置信息
  String? _locationErrorMessage; // 位置错误信息
  double? _targetLatitude; // 当前设置的目标纬度
  double? _targetLongitude; // 当前设置的目标经度
  String? _targetName; // 当前设置的目标名称
  double? _cachedTargetLatitude; // 缓存的导航目标纬度
  double? _cachedTargetLongitude; // 缓存的导航目标经度
  String? _cachedTargetName; // 缓存的导航目标名称

  @override
  void initState() {
    super.initState();
    _startCompass(); // 启动罗盘监听
    _getCurrentLocation(); // 获取当前位置
    _loadCachedNavigationTarget(); // 加载缓存的导航目标
  }

  // 启动罗盘监听
  void _startCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _heading = event.heading;
      });
    }, onError: (error) {
      print('Error getting compass data: $error');
    });
  }

  // 获取当前位置并开始监听位置更新
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationErrorMessage = '请打开手机定位服务。';
      });
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationErrorMessage = '请授权本应用获取位置信息。';
        });
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationErrorMessage = '本应用已被永久拒绝获取位置信息，请在设置中开启。';
      });
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Geolocator.getPositionStream().listen((Position position) {
      _speedBuffer.add(position.speed);
      if (_speedBuffer.length > _speedBufferSize) {
        _speedBuffer.removeAt(0);
      }
      double averageSpeed = _speedBuffer.isNotEmpty
          ? _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length
          : 0.0;

      setState(() {
        _currentPosition = position;
        _speed = averageSpeed;
        _locationErrorMessage = null;
      });
    }, onError: (error) {
      setState(() {
        _locationErrorMessage = '获取位置信息失败：$error';
      });
    });
  }

  // 加载缓存的导航目标
  Future<void> _loadCachedNavigationTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('navigation_target_latitude');
    final longitude = prefs.getDouble('navigation_target_longitude');
    final name = prefs.getString('navigation_target_name'); // 加载缓存的目标名称
    if (latitude != null && longitude != null) {
      setState(() {
        _cachedTargetLatitude = latitude;
        _cachedTargetLongitude = longitude;
        _cachedTargetName = name; // 保存缓存的目标名称
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const originalCompassSize = 200.0;
    final compassSize = originalCompassSize * 1.5;
    const compassTopPosition = 60.0;
    final compassLeftPosition = (screenWidth - compassSize) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('户外导航'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu), // 使用菜单图标
            onSelected: (String result) {
              if (result == 'destinations') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DestinationsListScreen()),
                );
              } else if (result == 'navigation') {
                // 优先使用缓存的目标，如果没有再使用当前设置的目标
                if (_cachedTargetLatitude != null && _cachedTargetLongitude != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        targetLatitude: _cachedTargetLatitude!,
                        targetLongitude: _cachedTargetLongitude!,
                        targetName: _cachedTargetName, // 传递缓存的目标名称
                      ),
                    ),
                  );
                } else if (_targetLatitude != null && _targetLongitude != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        targetLatitude: _targetLatitude!,
                        targetLongitude: _targetLongitude!,
                        targetName: _targetName, // 传递当前设置的目标名称
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请先设置目标坐标')),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'destinations',
                child: Text('目的地列表'),
              ),
              const PopupMenuItem<String>(
                value: 'navigation',
                child: Text('导航'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/compass.png', // 背景图片
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: compassTopPosition,
            left: compassLeftPosition,
            child: Container(
              width: compassSize,
              height: compassSize,
              child: Transform.rotate(
                angle: _heading != null ? -(_heading! * (pi / 180)) : 0,
                child: Image.asset(
                  'assets/compass_needle.png', // 罗盘图片
                  width: compassSize * 0.9,
                  height: compassSize * 0.9,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: compassTopPosition + compassSize + 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DirectionInfo(heading: _heading),
                  const SizedBox(height: 15),
                  SpeedInfo(speed: _speed),
                  const SizedBox(height: 15),
                  CoordinatesInfo(
                    currentPosition: _currentPosition,
                    locationErrorMessage: _locationErrorMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TargetCoordinatesScreen()),
          );

          if (result != null && result is Map<String, dynamic> && result.containsKey('latitude') && result.containsKey('longitude')) {
            setState(() {
              _targetLatitude = result['latitude'];
              _targetLongitude = result['longitude'];
              _targetName = result['name']; // 保存当前设置的目标名称
              // 清除缓存，因为设置了新的目标
              _cachedTargetLatitude = null;
              _cachedTargetLongitude = null;
              _cachedTargetName = null;
            });
          }
        },
        tooltip: '设置目标',
        child: const Icon(Icons.pin_drop),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}