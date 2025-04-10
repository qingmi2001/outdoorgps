import 'package:flutter/material.dart';

class SpeedInfo extends StatelessWidget {
  final double speed;

  const SpeedInfo({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    // 使用 Row 来实现左右两端对齐，显示速度标签和实际速度
    return Row(
      children: [
        // 显示 "当前速度：" 标签
        Text(
          '当前速度：',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // 使用 Expanded 让后面的 Text 占据剩余空间，并靠右对齐
        Expanded(
          child: Text(
            '${(speed * 3.6).toStringAsFixed(1)} KM/H',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
    // 注释：
    // 这个 Widget (SpeedInfo) 用于显示当前速度信息。
    // 它接收一个名为 'speed' 的参数，表示当前速度（单位为米/秒）。
    // build 方法中使用 Row 将 "当前速度：" 标签和实际速度信息左右对齐显示。
    // 速度值被乘以 3.6 并保留一位小数，以转换为千米/小时 (KM/H)。
    // 您可以通过修改 Text Widget 的 'style' 属性来改变字体样式。
    // 例如，修改字体大小：style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18.0),
    // 修改字体颜色：style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange),
    // 您也可以调整 Row 的布局方式，例如使用 MainAxisAlignment 来改变子元素的对齐方式。
  }
}