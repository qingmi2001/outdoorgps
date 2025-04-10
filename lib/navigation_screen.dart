import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // 导入 intl 包用于时间格式化
import 'package:flutter_compass/flutter_compass.dart'; // 导入 flutter_compass

class NavigationScreen extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final String? targetName; // 目标名称，可以为空

  const NavigationScreen({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    this.targetName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  double? _currentLatitude;
  double? _currentLongitude;
  double _distanceToTarget = 0.0;
  String _distanceUnit = '米';
  StreamSubscription<Position>? _locationSubscription;
  double? _bearingToTarget; // 当前位置到目标的角度
  List<double> _speedBuffer = []; // 速度缓冲队列
  int _speedBufferSize = 60; // 进一步增大速度缓冲大小
  double _speed = 0.0; // 实时速度
  double _minSpeedThreshold = 0.1; // m/s，低于此值认为静止
  double? _heading; // 当前设备朝向 (0-360 度，0 或 360 表示正北)
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _startCompass(); // 启动罗盘监听
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    _cacheNavigationTarget();
    super.dispose();
  }

  // 启动罗盘监听
  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _heading = event.heading;
      });
    }, onError: (error) {
      print('Error getting compass data: $error');
    });
  }

  // 缓存导航目标
  Future<void> _cacheNavigationTarget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('navigation_target_latitude', widget.targetLatitude);
    await prefs.setDouble('navigation_target_longitude', widget.targetLongitude);
    if (widget.targetName != null) {
      await prefs.setString('navigation_target_name', widget.targetName!);
    } else {
      await prefs.remove('navigation_target_name');
    }
  }

  // 清除缓存的导航目标
  Future<void> _clearCachedNavigationTarget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('navigation_target_latitude');
    await prefs.remove('navigation_target_longitude');
    await prefs.remove('navigation_target_name');
  }

  void _startLocationUpdates() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // 更频繁地更新位置以获取更准确的速度
      ),
    ).listen((Position position) {
      _speedBuffer.add(position.speed);
      if (_speedBuffer.length > _speedBufferSize) {
        _speedBuffer.removeAt(0);
      }
      double averageSpeed = _speedBuffer.isNotEmpty
          ? _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length
          : 0.0;

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _speed = averageSpeed > _minSpeedThreshold ? averageSpeed : 0.0; // 应用速度阈值
        _distanceToTarget = _calculateDistance(
          _currentLatitude!,
          _currentLongitude!,
          widget.targetLatitude,
          widget.targetLongitude,
        );
        _bearingToTarget = Geolocator.bearingBetween(
          _currentLatitude!,
          _currentLongitude!,
          widget.targetLatitude,
          widget.targetLongitude,
        );
        print('Bearing to target: $_bearingToTarget'); // 调试信息
        print('Heading: $_heading'); // 调试信息
        print('Raw Speed: ${position.speed}, Average Speed: $averageSpeed, Final Speed: $_speed'); // 调试信息
      });
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // 地球半径（米）
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final deltaLatRad = _toRadians(lat2 - lat1);
    final deltaLonRad = _toRadians(lon2 - lon1);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    final distance = R * c; // 单位为米
    if (distance > 1000) {
      _distanceUnit = '千米';
      return distance / 1000;
    } else {
      _distanceUnit = '米';
      return distance;
    }
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // 将十进制坐标转换为度分秒格式
  String _convertToDMS(double coordinate, bool isLatitude) {
    final absolute = coordinate.abs();
    final degrees = absolute.floor();
    final minutesDouble = (absolute - degrees) * 60;
    final minutes = minutesDouble.floor();
    final seconds = ((minutesDouble - minutes) * 60).toStringAsFixed(2);
    final direction = coordinate >= 0
        ? (isLatitude ? 'N' : 'E')
        : (isLatitude ? 'S' : 'W');
    return '$degrees°$minutes\'$seconds"$direction"';
  }

  // 计算预计到达时间
  String _calculateETA() {
    if (_speed > 0 && _distanceToTarget > 0) {
      final speedInKmH = _speed * 3.6; // 将速度转换为千米/小时
      if (speedInKmH > 0) {
        final timeInHours = _distanceToTarget / speedInKmH;
        final now = DateTime.now();
        final arrivalTime = now.add(Duration(seconds: (timeInHours * 3600).toInt()));
        final today = DateTime(now.year, now.month, now.day);
        final arrivalDate = DateTime(arrivalTime.year, arrivalTime.month, arrivalTime.day);

        if (arrivalDate.isAtSameMomentAs(today)) {
          final format = DateFormat('a h:mm'); // 上午/下午 时:分
          return format.format(arrivalTime);
        } else if (arrivalDate.year == today.year) {
          final format = DateFormat('MM月dd日 a h:mm'); // 月日 上午/下午 时:分
          return format.format(arrivalTime);
        } else {
          final format = DateFormat('yyyy年MM月dd日 a h:mm'); // 年月日 上午/下午 时:分
          return format.format(arrivalTime);
        }
      } else {
        return '计算中...'; // 速度为 0 时显示计算中
      }
    } else if (_distanceToTarget <= 0.01) { // 使用千米作为判断单位
      return '已到达';
    } else {
      return '计算中...';
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
        title: const Text('导航'),
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
            child: SizedBox(
              width: compassSize,
              height: compassSize,
              child: Transform.rotate(
                angle: _bearingToTarget != null && _heading != null
                    ? (math.pi / 180) * (_bearingToTarget! - (_heading! ?? 0))
                    : 0,
                child: Image.asset(
                  'assets/navigation_arrow.png', // 指向目标的箭头
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
                  if (widget.targetName != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('目的地:', style: Theme.of(context).textTheme.titleMedium),
                        Text(widget.targetName!, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('目标坐标:', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        '${_convertToDMS(widget.targetLatitude, true)}, ${_convertToDMS(widget.targetLongitude, false)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_currentLatitude != null && _currentLongitude != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('当前坐标:', style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '${_convertToDMS(_currentLatitude!, true)}, ${_convertToDMS(_currentLongitude!, false)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('距离目的地:', style: Theme.of(context).textTheme.headlineSmall),
                            Text('${_distanceToTarget.toStringAsFixed(2)} $_distanceUnit',
                                style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('实时速度:', style: Theme.of(context).textTheme.bodyMedium),
                            Text('${(_speed * 3.6).toStringAsFixed(1)} km/h', // 将 m/s 转换为 km/h
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('预计到达时间:', style: Theme.of(context).textTheme.bodyMedium),
                            Text(_calculateETA(), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    )
                  else
                    const Text('等待获取当前位置...'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _clearCachedNavigationTarget();
          Navigator.pop(context);
        },
        tooltip: '结束导航',
        child: const Icon(Icons.stop),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}