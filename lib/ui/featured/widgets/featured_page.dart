import 'package:flutter/material.dart';

class FeaturedPage extends StatelessWidget {
// 这是一个名为FeaturedPage的常量构造函数
// 使用const关键字声明这是一个编译时常量
// 接收一个可选的key参数，这是Flutter中Widget的标准做法
// super.key表示将key参数传递给父类构造函数
  const FeaturedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '精选页面\n这里将显示精选的音乐内容',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
