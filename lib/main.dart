import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'target_coordinates_screen.dart'; // 导入目标坐标输入页面
import 'direction_info.dart'; // 导入 DirectionInfo Widget
import 'speed_info.dart'; // 导入 SpeedInfo Widget
import 'coordinates_info.dart'; // 导入 CoordinatesInfo Widget

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
  double? _heading; // 当前设备朝向，单位为度
  List<double> _speedBuffer = []; // 用于存储最近的速度值，实现移动平均滤波
  int _speedBufferSize = 5; // 定义速度缓冲区的最大大小
  double _speed = 0.0; // 当前速度，单位为米/秒
  Position? _currentPosition; // 当前地理位置信息
  String? _locationErrorMessage; // 位置信息错误消息
  double? _targetLatitude; // 目标纬度
  double? _targetLongitude; // 目标经度

  @override
  void initState() {
    super.initState();
    _startCompass(); // 在 Widget 初始化时启动罗盘监听
    _getCurrentLocation(); // 在 Widget 初始化时获取当前地理位置
  }

  // 启动罗盘监听
  void _startCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _heading = event.heading; // 当罗盘数据更新时，更新 _heading 状态
      });
    }, onError: (error) {
      print('Error getting compass data: $error'); // 打印罗盘数据获取错误信息
    });
  }

  // 获取当前地理位置
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查位置服务是否已启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationErrorMessage = '请打开手机定位服务。'; // 如果位置服务未启用，设置错误消息
      });
      return Future.error('Location services are disabled.');
    }

    // 检查位置权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // 请求位置权限
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationErrorMessage = '请授权本应用获取位置信息。'; // 如果权限被拒绝，设置错误消息
        });
        return Future.error('Location permissions are denied');
      }
    }

    // 如果权限被永久拒绝
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationErrorMessage = '本应用已被永久拒绝获取位置信息，请在设置中开启。'; // 如果权限被永久拒绝，设置错误消息
      });
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 监听位置信息流
    Geolocator.getPositionStream().listen((Position position) {
      _speedBuffer.add(position.speed); // 将新的速度值添加到速度缓冲区
      if (_speedBuffer.length > _speedBufferSize) {
        _speedBuffer.removeAt(0); // 如果缓冲区已满，移除最旧的速度值
      }
      // 计算缓冲区中速度值的平均值，实现速度的平滑显示
      double averageSpeed = _speedBuffer.isNotEmpty
          ? _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length
          : 0.0;

      setState(() {
        _currentPosition = position; // 当位置信息更新时，更新 _currentPosition 状态
        _speed = averageSpeed; // 更新平滑后的速度状态
        _locationErrorMessage = null; // 清空错误消息
      });
    }, onError: (error) {
      setState(() {
        _locationErrorMessage = '获取位置信息失败：$error'; // 如果获取位置信息失败，设置错误消息
      });
    });
  }

  // 计算到目标坐标的方位角
  double? _bearingToTarget() {
    if (_currentPosition != null && _targetLatitude != null && _targetLongitude != null) {
      return Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _targetLatitude!,
        _targetLongitude!,
      );
    }
    return null;
  }

  // 根据方位角获取中文方向
  String _getChineseDirection(double? bearing) {
    if (bearing == null) {
      return '';
    }
    const threshold = 11.25; // 每个方向的半个角度范围
    const directions = [
      '正北', '东北偏北', '东北', '东北偏东', '正东', '东南偏东', '东南', '东南偏南',
      '正南', '西南偏南', '西南', '西南偏西', '正西', '西北偏西', '西北', '西北偏北', '正北'
    ];
    final index = ((bearing + threshold) / 22.5).floor();
    return directions[index.clamp(0, 15)];
  }

  // 计算预计到达时间
  String _calculateETA() {
    if (_targetLatitude == null ||
        _targetLongitude == null ||
        _currentPosition == null ||
        _speed == 0) {
      return '等待数据...';
    }

    final double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetLatitude!,
      _targetLongitude!,
    );

    if (_speed > 0) {
      final double timeInSeconds = distance / _speed;
      final int minutes = (timeInSeconds / 60).floor();
      final int seconds = (timeInSeconds % 60).floor();
      if (minutes > 59) {
        final int hours = (minutes / 60).floor();
        final int remainingMinutes = minutes % 60;
        return '${hours}小时${remainingMinutes.toString().padLeft(2, '0')}分';
      } else {
        return '${minutes}分${seconds.toString().padLeft(2, '0')}秒';
      }
    } else {
      return '停止';
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
        title: const Text('户外导航'), // 设置 App Bar 的标题
        centerTitle: true, // 将标题居中显示
      ),
      body: Stack( // 使用 Stack Widget 可以让子元素层叠显示
        children: [
          // 全屏背景图片
          Positioned.fill(
            child: Image.asset(
              'assets/compass.png',
              fit: BoxFit.cover, // 让图片填充整个屏幕
            ),
          ),
          // 箭头 Widget (替换了罗盘指针)
          Positioned(
            top: compassTopPosition, // 设置箭头 Widget 的顶部位置
            left: compassLeftPosition, // 设置箭头 Widget 的左侧位置
            child: Container(
              width: compassSize, // 设置箭头容器的宽度
              height: compassSize, // 设置箭头容器的高度
              child: Transform.rotate( // 使用 Transform.rotate Widget 旋转箭头
                angle: (_targetLatitude != null && _targetLongitude != null && _heading != null && _bearingToTarget() != null)
                    ? (_bearingToTarget()! - _heading!) * (pi / 180)
                    : 0,
                child: Image.asset(
                  'assets/navigation_arrow.png', // 替换为您的箭头图片
                  width: compassSize * 0.9,
                  height: compassSize * 0.9,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // 显示当前方向、速度和坐标信息的容器
          Positioned(
            top: compassTopPosition + compassSize + 30, // 设置信息容器的顶部位置
            left: 20, // 设置信息容器的左侧边距
            right: 20, // 设置信息容器的右侧边距
            child: Container(
              padding: const EdgeInsets.all(16.0), // 设置容器的内边距
              decoration: BoxDecoration( // 设置容器的背景和边框样式
                color: Colors.white.withOpacity(0.8), // 白色半透明背景
                borderRadius: BorderRadius.circular(10), // 圆角边框
                boxShadow: [ // 阴影效果
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column( // 使用 Column 来垂直排列文本行
                crossAxisAlignment: CrossAxisAlignment.start, // 保持左对齐
                children: <Widget>[
                  // 当前方向信息 (使用了独立的 DirectionInfo Widget)
                  DirectionInfo(heading: _heading),
                  const SizedBox(height: 15), // 添加垂直间距
                  // 当前速度信息 (使用了独立的 SpeedInfo Widget)
                  SpeedInfo(speed: _speed),
                  const SizedBox(height: 15), // 添加垂直间距
                  // 当前坐标信息 (使用了独立的 CoordinatesInfo Widget)
                  CoordinatesInfo(
                    currentPosition: _currentPosition,
                    locationErrorMessage: _locationErrorMessage,
                  ),
                  if (_targetLatitude != null && _targetLongitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '指向：${_getChineseDirection(_bearingToTarget())}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '距离：${_currentPosition != null ? Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              _targetLatitude!,
                              _targetLongitude!,
                            ).toStringAsFixed(2) : '获取中...'} 米',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '预计到达时间：${_calculateETA()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  if (_targetLatitude != null && _targetLongitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        '目标已设置', // 显示目标已设置的提示
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 添加 FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 导航到 TargetCoordinatesScreen 并等待结果
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TargetCoordinatesScreen()),
          );

          // 如果 result 不为空，则表示用户设置了目标坐标
          if (result != null && result is Map<String, double>) {
            setState(() {
              _targetLatitude = result['latitude'];
              _targetLongitude = result['longitude'];
              print('目标纬度: $_targetLatitude, 目标经度: $_targetLongitude');
              final bearing = _bearingToTarget();
              print('方位角到目标: $bearing 度');
              // TODO: 在这里开始导航相关的逻辑，例如显示箭头等
            });
          }
        },
        tooltip: '设置目标', // 设置按钮的提示文本
        child: const Icon(Icons.pin_drop), // 使用一个定位图标
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // 设置FAB的位置
    );
  }
}