import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class RollingText extends StatelessWidget {
  final String text;

  RollingText({this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Center(
        child: Marquee(
          text: text,
          style: TextStyle(
            fontFamily: "5by7",
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Color.fromRGBO(254, 178, 42, 1),
          ),
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 20.0,
          velocity: 40.0,
          showFadingOnlyWhenScrolling: true,
          fadingEdgeStartFraction: 0.1,
          fadingEdgeEndFraction: 0.1,
          startPadding: 10.0,
        ),
      ),
    );
  }
}
