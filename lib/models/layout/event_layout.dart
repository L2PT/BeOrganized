// Classe per rappresentare un evento con le sue proprietà di layout
import 'package:venturiautospurghi/models/event.dart';

class EventLayout {
  final Event event;
  final double top;
  final double height;
  final int column;
  final int totalColumns;
  final double width;
  final double left;

  EventLayout({
    required this.event,
    required this.top,
    required this.height,
    required this.column,
    required this.totalColumns,
    required this.width,
    required this.left,
  });
}
