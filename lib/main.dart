import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

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
  double? _heading;
  List<double> _speedBuffer = [];
  int _speedBufferSize = 5;
  double _speed = 0.0;
  Position? _currentPosition;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    _startCompass();
    _getCurrentLocation();
  }

  void _startCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _heading = event.heading;
      });
    }, onError: (error) {
      print('Error getting compass data: $error');
    });
  }

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

  String _getCurrentDirection(double? heading) {
    if (heading == null) {
      return '';
    }
    const threshold = 22.5;
    final directions = [
      '北', '东北', '东', '东南', '南', '西南', '西', '西北', '北'
    ];
    final index = ((heading + threshold) / 45).floor();
    final direction = directions[index.clamp(0, 8)];
    return '$direction (${heading.toStringAsFixed(1)}°)';
  }

  String _formatCoordinate(double coordinate, bool isLongitude) {
    final degrees = coordinate.floor();
    final minutes = ((coordinate - degrees) * 60).floor();
    final seconds = (((coordinate - degrees) * 60) - minutes) * 60;
    final absDegrees = degrees.abs();
    String direction;

    if (isLongitude) {
      direction = coordinate >= 0 ? 'E' : 'W';
    } else {
      direction = coordinate >= 0 ? 'N' : 'S';
    }

    return '${absDegrees}°${minutes.toString().padLeft(2, '0')}′${seconds.toStringAsFixed(1).padLeft(4, '0')}″ ${direction}';
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/compass.png',
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
                  'assets/compass_needle.png',
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
                  Text(
                    '当前方向：${_getCurrentDirection(_heading)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '当前速度：${(_speed * 3.6).toStringAsFixed(1)} KM/H',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '当前坐标：',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_currentPosition != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '经度：${_formatCoordinate(_currentPosition!.longitude, true)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '纬度：${_formatCoordinate(_currentPosition!.latitude, false)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  else
                    Text(
                      _locationErrorMessage ?? '当前坐标：获取中...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor) ?? const TextStyle(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}