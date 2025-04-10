import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入用于限制输入格式的库

class TargetCoordinatesScreen extends StatefulWidget {
  const TargetCoordinatesScreen({super.key});

  @override
  State<TargetCoordinatesScreen> createState() => _TargetCoordinatesScreenState();
}

class _TargetCoordinatesScreenState extends State<TargetCoordinatesScreen> {
  // 用于存储用户输入的纬度和经度信息
  String? _latitudeHemisphere;
  int? _latitudeDegrees;
  int? _latitudeMinutes;
  double? _latitudeSeconds;

  String? _longitudeHemisphere;
  int? _longitudeDegrees;
  int? _longitudeMinutes;
  double? _longitudeSeconds;

  // 纬度和经度的下拉选项，使用中文全称
  final List<String> _latitudeHemispheres = ['北纬', '南纬'];
  final List<String> _longitudeHemispheres = ['东经', '西经'];

  // 控制器用于获取输入框的值
  final TextEditingController _latitudeDegreesController = TextEditingController();
  final TextEditingController _latitudeMinutesController = TextEditingController();
  final TextEditingController _latitudeSecondsController = TextEditingController();
  final TextEditingController _longitudeDegreesController = TextEditingController();
  final TextEditingController _longitudeMinutesController = TextEditingController();
  final TextEditingController _longitudeSecondsController = TextEditingController();

  // 用于显示错误信息
  String? _latitudeError;
  String? _longitudeError;

  // 验证输入的度分秒是否有效并转换为十进制坐标
  Map<String, double>? _validateAndConvertToDecimal() {
    if (_latitudeHemisphere == null ||
        _latitudeDegrees == null ||
        _latitudeMinutes == null ||
        _latitudeSeconds == null ||
        _longitudeHemisphere == null ||
        _longitudeDegrees == null ||
        _longitudeMinutes == null ||
        _longitudeSeconds == null) {
      setState(() {
        _latitudeError = _latitudeHemisphere == null ? '请选择纬度' : _latitudeError;
        _longitudeError = _longitudeHemisphere == null ? '请选择经度' : _longitudeError;
        _latitudeError = _latitudeDegrees == null ? '请输入纬度度' : _latitudeError;
        _latitudeError = _latitudeMinutes == null ? '请输入纬度分' : _latitudeError;
        _latitudeError = _latitudeSeconds == null ? '请输入纬度秒' : _latitudeError;
        _longitudeError = _longitudeDegrees == null ? '请输入经度度' : _longitudeError;
        _longitudeError = _longitudeMinutes == null ? '请输入经度分' : _longitudeError;
        _longitudeError = _longitudeSeconds == null ? '请输入经度秒' : _longitudeError;
      });
      return null;
    }

    bool isValid = true;
    double? decimalLatitude;
    double? decimalLongitude;

    setState(() {
      _latitudeError = null;
      _longitudeError = null;

      // 纬度验证
      if (_latitudeDegrees! < 0 || _latitudeDegrees! > 90) {
        _latitudeError = '纬度度数范围应为 0-90';
        isValid = false;
      }
      if (_latitudeMinutes! < 0 || _latitudeMinutes! > 59) {
        _latitudeError = '纬度分钟范围应为 0-59';
        isValid = false;
      }
      if (_latitudeSeconds! < 0 || _latitudeSeconds! >= 60) {
        _latitudeError = '纬度秒数范围应为 0-59.999...';
        isValid = false;
      }

      // 经度验证
      if (_longitudeDegrees! < 0 || _longitudeDegrees! > 180) {
        _longitudeError = '经度度数范围应为 0-180';
        isValid = false;
      }
      if (_longitudeMinutes! < 0 || _longitudeMinutes! > 59) {
        _longitudeError = '经度分钟范围应为 0-59';
        isValid = false;
      }
      if (_longitudeSeconds! < 0 || _longitudeSeconds! >= 60) {
        _longitudeError = '经度秒数范围应为 0-59.999...';
        isValid = false;
      }
    });

    if (isValid) {
      // 转换为十进制纬度
      decimalLatitude = _latitudeDegrees! + (_latitudeMinutes! / 60) + (_latitudeSeconds! / 3600);
      if (_latitudeHemisphere == '南纬') {
        decimalLatitude = -decimalLatitude;
      }

      // 转换为十进制经度
      decimalLongitude = _longitudeDegrees! + (_longitudeMinutes! / 60) + (_longitudeSeconds! / 3600);
      if (_longitudeHemisphere == '西经') {
        decimalLongitude = -decimalLongitude;
      }

      return {'latitude': decimalLatitude, 'longitude': decimalLongitude};
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const labelFontSize = 14.0; // 设置一个期望的标签字体大小

    return Scaffold(
      appBar: AppBar(
        title: const Text('输入目标坐标'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 经度输入部分
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('经度', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        // 经度东西选择下拉框
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '选择经度',
                              border: OutlineInputBorder(),
                            ),
                            value: _longitudeHemisphere,
                            items: _longitudeHemispheres.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _longitudeHemisphere = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 经度 度
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _longitudeDegreesController,
                            decoration: InputDecoration(
                              labelText: '度',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              _longitudeDegrees = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 经度 分
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _longitudeMinutesController,
                            decoration: InputDecoration(
                              labelText: '分',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              _longitudeMinutes = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 经度 秒
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeSecondsController,
                            decoration: InputDecoration(
                              labelText: '秒',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _longitudeSeconds = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_longitudeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _longitudeError!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 纬度输入部分
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('纬度', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        // 纬度南北选择下拉框
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '选择纬度',
                              border: OutlineInputBorder(),
                            ),
                            value: _latitudeHemisphere,
                            items: _latitudeHemispheres.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _latitudeHemisphere = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 纬度 度
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _latitudeDegreesController,
                            decoration: InputDecoration(
                              labelText: '度',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              _latitudeDegrees = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 纬度 分
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _latitudeMinutesController,
                            decoration: InputDecoration(
                              labelText: '分',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              _latitudeMinutes = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 纬度 秒
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeSecondsController,
                            decoration: InputDecoration(
                              labelText: '秒',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(fontSize: labelFontSize), // 设置标签字体大小
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              _latitudeSeconds = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_latitudeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _latitudeError!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final coordinates = _validateAndConvertToDecimal();
                if (coordinates != null) {
                  Navigator.pop(context, coordinates); // 将转换后的坐标返回
                }
              },
              child: const Text('设置目标'),
            ),
          ],
        ),
      ),
    );
  }
}