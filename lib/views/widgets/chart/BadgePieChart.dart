import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class BadgePieChart extends StatelessWidget {
  const BadgePieChart(this.icon, {
    required this.size,
    required this.borderColor,
    this.activeColor = yellow,
    this.active = false,
    this.tooltipText = '',
  });

  final IconData? icon;
  final String tooltipText;
  final double size;
  final Color borderColor;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
          duration: PieChart.defaultDuration,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: white,
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
              child: Tooltip(child:  Icon(icon, size: 16, color: active?activeColor:grey_dark,), message: tooltipText,)
          ),
    );
  }
}