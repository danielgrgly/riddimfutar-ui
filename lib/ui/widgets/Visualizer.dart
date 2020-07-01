import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import "../../core/models/TripDetails.dart";
import '../../core/models/Vehicle.dart';
import "../screens/futar.dart";

class Visualizer extends StatefulWidget {
  Visualizer({this.trip, this.futarKey});

  final GlobalKey<FutarState> futarKey;
  final TripDetails trip;

  @override
  _VisualizerState createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    rotate();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void rotate() async {
    _controller.forward(from: 0);

    await new Future.delayed(const Duration(seconds: 4), () {
      rotate();
    });
  }

  @override
  Widget build(BuildContext context) {
    double _maxSize = MediaQuery.of(context).size.width;
    double _baseSize = _maxSize / 3;

    return OverflowBox(
      child: StreamBuilder<int>(
          stream: widget.futarKey.currentState.sound.waveformStream(),
          builder: (context, snapshot) {
            return Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      curve: Curves.linear,
                      width: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 3000, 0.125),
                      ),
                      height: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 3000, 0.125),
                      ),
                      decoration: BoxDecoration(
                        color: widget.trip.color.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.all(Radius.circular(10000000)),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      curve: Curves.linear,
                      width: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 5000, 0.25),
                      ),
                      height: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 5000, 0.25),
                      ),
                      decoration: BoxDecoration(
                        color: widget.trip.color.withOpacity(0.5),
                        borderRadius:
                            BorderRadius.all(Radius.circular(10000000)),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      curve: Curves.linear,
                      width: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 8000, 0.5),
                      ),
                      height: min(
                        _maxSize,
                        _baseSize * max(snapshot.data / 8000, 0.5),
                      ),
                      child: RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                        child: SvgPicture.asset(
                          iconPath(widget.trip.type),
                          semanticsLabel: 'visualizer',
                        ),
                      ),
                    ),
                  ],
                ));
          }),
    );
  }
}
