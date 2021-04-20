import 'package:flutter/material.dart';

class MainToastWidget extends StatelessWidget {
  MainToastWidget({this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        color: Colors.black87,
        width: 200,
        height: 50,
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
