// Classe per gestire gruppi di eventi sovrapposti
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/layout/event_layout.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/date_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

class OverlappingGroup {
  List<Event> events = [];
  int maxColumns = 1;
  Map<Event, int> eventColumns = {};

  void addEvent(Event event) {
    events.add(event);
    events.sort((a, b) => a.start.compareTo(b.start));
  }

  bool overlaps(Event event) {
    return events.any((existingEvent) => existingEvent.isEventsOverlap(event.start, event.end));
  }

  /// Calcola il numero massimo di colonne e assegna ogni evento alla sua colonna
  void calculateAndAssignColumns() {
    if (events.isEmpty) {
      maxColumns = 0;
      return;
    }

    List<DateTime> columnEndTimes = [];
    eventColumns.clear(); // Pulisce le assegnazioni precedenti

    for (Event event in events) {
      // Trova la prima colonna disponibile
      int availableColumn = -1;
      for (int i = 0; i < columnEndTimes.length; i++) {
        if (_.DateUtils.isBefore(columnEndTimes[i],event.start) ||
            _.DateUtils.isAtSameMomentAs(columnEndTimes[i],event.start)) {
          availableColumn = i;
          break;
        }
      }

      if (availableColumn == -1) {
        // Nessuna colonna disponibile, aggiungi una nuova colonna
        columnEndTimes.add(event.end);
        availableColumn = columnEndTimes.length - 1;
      } else {
        // Usa la colonna disponibile
        columnEndTimes[availableColumn] = event.end;
      }

      // Assegna l'evento alla colonna
      eventColumns[event] = availableColumn;
    }

    // Aggiorna il numero massimo di colonne
    maxColumns = columnEndTimes.length;
  }

  List<EventLayout> calculateGroupLayout(
      double containerWidth,
      DateTime selectDay,
      { int gridHourSpan = 1,
        double gridHourHeight = 100,
        DateTime? baseTime
      }
      ) {
    List<EventLayout> layouts = [];

    calculateAndAssignColumns();
    baseTime = baseTime??DateTime(1990, 1, 1, Constants.MIN_WORKTIME, 0, 0);
    // Calcola la larghezza delle colonne
    double columnWidth = containerWidth / maxColumns;
    double marginBetweenColumns = maxColumns > 1 ? 2.0 : 0.0;
    double effectiveColumnWidth = columnWidth - marginBetweenColumns;

    // Crea i layout per ogni evento
    for (Event event in events) {
      int column = eventColumns[event]!;

      double top = DateUtils.calcWidgetHeightInGrid(
          selectDay, gridHourSpan, gridHourHeight,
          firstWorkedMinute: baseTime.hour * 60 + baseTime.minute,
          end: event.start
      );

      double height = DateUtils.calcWidgetHeightInGrid(
          selectDay, gridHourSpan, gridHourHeight,
          start: event.start,
          end: event.end
      );

      layouts.add(EventLayout(
        event: event,
        top: top,
        height: height,
        column: column,
        totalColumns: maxColumns,
        width: effectiveColumnWidth,
        left: column * columnWidth,
      ));
    }

    return layouts;
  }

}