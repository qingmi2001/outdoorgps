import 'package:flutter/material.dart';

class DirectionInfo extends StatelessWidget {
  final double? heading;

  const DirectionInfo({super.key, required this.heading});

  // 根据设备朝向获取当前方向的文字描述
  String _getCurrentDirection(double? heading) {
    if (heading == null) {
      return '';
    }
    const threshold = 22.5;
    const directions = [
      '北', '东北', '东', '东南', '南', '西南', '西', '西北', '北'
    ];
    final index = ((heading + threshold) / 45).floor();
    final direction = directions[index.clamp(0, 8)];
    return '$direction (${heading.toStringAsFixed(1)}°)';
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Row 来实现左右两端对齐，显示方向标签和实际方向
    return Row(
      children: [
        // 显示 "当前方向：" 标签
        Text(
          '当前方向：',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        // 使用 Expanded 让后面的 Text 占据剩余空间，并靠右对齐
        Expanded(
          child: Text(
            _getCurrentDirection(heading),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
    // 注释：
    // 这个 Widget (DirectionInfo) 用于显示当前方向信息。
    // 它接收一个名为 'heading' 的参数，表示设备朝向的角度。
    // _getCurrentDirection 方法根据角度计算出方向的文字描述。
    // build 方法中使用 Row 将 "当前方向：" 标签和实际方向信息左右对齐显示。
    // 您可以通过修改 Text Widget 的 'style' 属性来改变字体样式。
    // 例如，修改字体大小：style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
    // 修改字体颜色：style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
    // 您也可以调整 Row 的布局方式，例如使用 MainAxisAlignment 来改变子元素的对齐方式。
  }
}