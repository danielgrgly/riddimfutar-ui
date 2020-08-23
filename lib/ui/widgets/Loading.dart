import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final String title;

  Loading(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.white,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}
