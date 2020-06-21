import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import "../../core/models/TripDetails.dart";
import '../../core/models/Vehicle.dart';

class Visualizer extends StatefulWidget {
  Visualizer({this.trip});

  final TripDetails trip;

  @override
  _VisualizerState createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer> with TickerProviderStateMixin {
  double _width = 150;
  double _height = 150;
  double _rotation = 0;

  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    kickoffRotate();

    super.initState();
  }

  void kickoffRotate() async {
    _controller.forward(from: 0);

    while (true) {
      // You have to provide a condition to know when to stop
      await new Future.delayed(const Duration(seconds: 4), () {
        _controller.forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 10),
          curve: Curves.linear,
          width: _width,
          height: _height,
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
            child: SvgPicture.asset(
              iconPath(widget.trip.type),
              semanticsLabel: 'visualizer',
            ),
          ),
        ),
      ),
    );
  }
}
