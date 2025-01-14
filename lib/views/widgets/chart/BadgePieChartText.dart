import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class BadgePieChartText extends StatelessWidget {
  const BadgePieChartText(this.text, {
    required this.size,
    required this.borderColor,
    this.backgroundColor = white,
    this.active = false,
    this.tooltipText = '',
  });

  final String text;
  final String tooltipText;
  final double size;
  final Color borderColor;
  final bool active;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
          duration: PieChart.defaultDuration,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: black.withOpacity(.5),
                offset: const Offset(3, 3),
                blurRadius: 3,
              ),
            ],
          ),
          padding: EdgeInsets.all(size * .15),
          child: Center(
              child: Tooltip(message: tooltipText, child: Text(text, style:
              TextStyle(fontSize: active?15:13.0, fontWeight: FontWeight.bold, color: const Color(0xffffffff),),))
          ),
    );
  }
}