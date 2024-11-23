// ignore_for_file: file_names

import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';

class CircularButtonDesign extends StatefulWidget {
  Color? color;
  BorderRadiusGeometry? borderRadius;
  Widget? iconWidget;
  IconData icon;
  bool whiteTheme;
  Function()? onTap;

  double? height;
  double? width;
  bool topLeftRadius;
  CircularButtonDesign(
      {required this.icon,
      this.iconWidget,
      this.color,
      this.onTap,
      this.height,
      this.width,
      this.borderRadius,
      this.topLeftRadius = false,
      this.whiteTheme = false,
      super.key});

  @override
  State<CircularButtonDesign> createState() => _CircularButtonDesignState();
}

class _CircularButtonDesignState extends State<CircularButtonDesign> {
  bool isElevated = false;
  int designType = 0;

  @override
  Widget build(BuildContext context) {
    Offset distance = isElevated ? const Offset(5, 5) : const Offset(5, 5);
    double blur = isElevated ? 15.0 : 15.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height ?? 100,
      width: widget.width ?? 100,
      decoration: designType == 0
          ? BoxDecoration(
              color: Color(0xFF649166),
              //  border: Border.fromBorderSide(BorderSide(style: BorderStyle.solid,width: 3.0,color: Color(0xFFF8F1F1))),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.whiteTheme
                    ? [
                        Color.fromARGB(255, 244, 244, 244),
                        Colors.white,
                        Color.fromARGB(255, 236, 236, 236)
                      ]
                    : [
                        Color.fromARGB(255, 32, 32, 32),
                        Color.fromARGB(255, 21, 21, 21),
                        Colors.black
                      ],
                stops: [0.1, 0.5, 0.9],
              ),
            )
          : designType == 1
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0xFFf8fbf8),
                  boxShadow: [
                      BoxShadow(
                          color: Colors.grey[200]!,
                          offset: Offset(10.0, 10.0),
                          blurRadius: 10.0,
                          spreadRadius: 2.0),
                      BoxShadow(
                          color: Colors.white,
                          offset: Offset(-10.0, -10.0),
                          blurRadius: 10.0,
                          spreadRadius: 2.0)
                    ])
              : BoxDecoration(
                  color: widget.whiteTheme
                      ? Colors.white
                      : Color.fromARGB(255, 21, 21, 21),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color:
                          widget.whiteTheme ? Colors.grey[300]! : Colors.black,
                      offset: distance,
                      blurRadius: blur,
                      spreadRadius: 1,
                      inset: isElevated,
                    ),
                    BoxShadow(
                      color: widget.whiteTheme
                          ? Colors.blueGrey[100]!
                          : Colors.grey.withOpacity(0.3),
                      offset: -distance,
                      blurRadius: blur,
                      spreadRadius: 1,
                      inset: isElevated,
                    )
                  ],
                ),
      child: Center(
          child: GestureDetector(
              onTap: widget.onTap == null
                  ? null
                  : () {
                      widget.onTap!();
                    },
              child: Container(
                  child: widget.iconWidget ??
                      Icon(
                        widget.icon,
                        size: 40,
                        color: widget.whiteTheme ? Colors.black : Colors.grey,
                      )))),
    );

    // const Icon(Icons.home, size: 40, color: Colors.green),

    //),
    // ));
  }
}
