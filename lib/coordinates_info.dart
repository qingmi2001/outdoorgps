import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CoordinatesInfo extends StatelessWidget {
  final Position? currentPosition;
  final String? locationErrorMessage;

  const CoordinatesInfo({super.key, required this.currentPosition, this.locationErrorMessage});

  // 格式化经纬度坐标
  String _formatCoordinate(double coordinate, bool isLongitude) {
    final degrees = coordinate.floor(); // 获取整数部分（度）
    final minutes = ((coordinate - degrees) * 60).floor(); // 获取分钟
    final seconds = (((coordinate - degrees) * 60) - minutes) * 60; // 获取秒
    final absDegrees = degrees.abs(); // 获取绝对值，用于显示度数
    String direction;

    if (isLongitude) {
      direction = coordinate >= 0 ? 'E' : 'W'; // 东经 (East) 和 西经 (West)
    } else {
      direction = coordinate >= 0 ? 'N' : 'S'; // 北纬 (North) 和 南纬 (South)
    }

    return '${absDegrees}°${minutes.toString().padLeft(2, '0')}′${seconds.toStringAsFixed(1).padLeft(4, '0')}″ ${direction}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示 "当前坐标：" 标签
        Text(
          '当前坐标：',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        // 根据是否有位置信息显示不同的内容
        if (currentPosition != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示经度信息
              Row(
                children: [
                  Text(
                    '经度：',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: Text(
                      _formatCoordinate(currentPosition!.longitude, true),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              // 显示纬度信息
              Row(
                children: [
                  Text(
                    '纬度：',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: Text(
                      _formatCoordinate(currentPosition!.latitude, false),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
        // 如果没有位置信息，显示错误消息或加载中的提示
          Text(
            locationErrorMessage ?? '当前坐标：获取中...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor) ?? const TextStyle(),
          ),
      ],
    );
    // 注释：
    // 这个 Widget (CoordinatesInfo) 用于显示当前的地理坐标信息。
    // 它接收两个参数：
    //   - 'currentPosition': 一个 Position 对象，包含当前的经纬度信息。
    //   - 'locationErrorMessage': 一个字符串，用于在获取位置信息失败时显示错误消息。
    // _formatCoordinate 方法用于将经纬度坐标格式化为度、分、秒的形式。
    // build 方法首先显示 "当前坐标：" 标签。
    // 然后根据 'currentPosition' 是否为空来显示不同的内容：
    //   - 如果 'currentPosition' 不为空，则显示格式化后的经度和纬度信息。
    //   - 如果 'currentPosition' 为空，则显示 'locationErrorMessage' 或者默认的 "当前坐标：获取中..." 消息。
    // 您可以通过修改 Text Widget 的 'style' 属性来改变字体样式。
    // 例如，修改经纬度标签的字体颜色：style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green),
    // 修改坐标值的字体大小：style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 17.0),
    // 您也可以调整 Row 和 Column 的布局方式来改变信息的排列方式。
  }
}