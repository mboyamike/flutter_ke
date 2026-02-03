import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    
    return  Scaffold(
      appBar: AppBar(title: Text('Flutter Ke'),),
    );
  }
}