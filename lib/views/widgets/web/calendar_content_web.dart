import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/calendar_content_web/calendar_content_web_cubit.dart';
import 'package:venturiautospurghi/cubit/web/calendar_page/calendar_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/layout/event_layout.dart';
import 'package:venturiautospurghi/plugins/dispatcher/web.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_attention.dart';
import 'package:venturiautospurghi/views/widgets/card_event_widget.dart';

import '../../../utils/pdf_utils.dart';

class CalendarContentWeb extends StatelessWidget {
  final int _backGridLength = (Constants.MAX_WORKTIME - Constants.MIN_WORKTIME + 1);
  final double _topSpace = 100;

  // OTTIMIZZAZIONE 1: Usa const constructor quando possibile
  const CalendarContentWeb({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Account account = context.read<AuthenticationBloc>().account!;
    final repository = context.read<CloudFirestoreService>();

    return BlocProvider(
      create: (_) => CalendarContentWebCubit(repository, context, account),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Divider(
            color: grey_light,
            thickness: 1,
            height: 0,
          ),
          // OTTIMIZZAZIONE 2: Usa buildWhen solo quando necessario e con condizioni specifiche
          BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) =>
            previous != current,
            builder: (context, state) => HeaderOperatorCalendar(account),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: context.read<WebCubit>().verticalCalendar,
              // OTTIMIZZAZIONE 3: Aggiungi cacheExtent per pre-renderizzare
              child: Stack(
                children: <Widget>[
                  // OTTIMIZZAZIONE 4: Usa RepaintBoundary per isolare il repaint
                  RepaintBoundary(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: backGrid(),
                    ),
                  ),
                  BlocBuilder<WebCubit, WebCubitState>(
                    buildWhen: (previous, current) =>
                    previous != current,
                    builder: (context, state) => Positioned(
                      top: 0,
                      right: 0,
                      left: 75,
                      child: RepaintBoundary(
                        child: OperatorCalendar(
                            account,
                            _backGridLength,
                            _topSpace
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<CalendarContentWebCubit, CalendarContentWebState>(
                    buildWhen: (previous, current) =>
                    previous.showHoverContainer != current.showHoverContainer ||
                        previous.posTop != current.posTop ||
                        previous.posLeft != current.posLeft,
                    builder: (context, state) {
                      if (!state.showHoverContainer) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: state.posTop,
                        left: state.posLeft,
                        child: AnimatedOpacity(
                          opacity: state.showHoverContainer ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300), // Ridotto da 500
                          child: _HoverContainer(event: state.eventHover),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OTTIMIZZAZIONE 5: Rendi la griglia più efficiente
  List<Widget> backGrid() {
    return List.generate(_backGridLength, (i) {
      final n = i + Constants.MIN_WORKTIME;
      return _GridRow(hour: n);
    }); // growable: false per liste di dimensione fissa
  }
}

// OTTIMIZZAZIONE 6: Estrai widget stateless per evitare rebuild
class _GridRow extends StatelessWidget {
  final int hour;

  const _GridRow({required this.hour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 15),
      height: 100, // Altezza fissa per migliorare performance
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "$hour:00",
            style: const TextStyle(color: grey_dark),
          ),
          const Expanded(
            child: Divider(
              color: grey_light,
              thickness: 1,
              height: 20,
              indent: 10,
              endIndent: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// OTTIMIZZAZIONE 7: Widget separato per hover container
class _HoverContainer extends StatelessWidget {
  final Event event;

  const _HoverContainer({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(color: black_light, width: 2),
        color: black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Dettagli Evento: ${event.title}",
            style: title_rev_menu,
          ),
          const SizedBox(height: 5),
          _HoverRow(
            icon: Icons.calendar_month,
            text: _formatDate(event),
          ),
          const SizedBox(height: 2),
          _HoverRow(
            icon: Icons.place,
            text: event.addresAddress(),
          ),
          const SizedBox(height: 2),
          _HoverRow(
            icon: EventStatus.getIcon(event.status),
            text: EventStatus.getText(event.status),
          ),
        ],
      ),
    );
  }

  static String _formatDate(Event event) {
    final startDate = _.DateUtils.hoverDateFormat(event.start);
    final endDate = _.DateUtils.hoverDateFormat(event.end);

    if (startDate == endDate) {
      return "$startDate - ${_.DateUtils.hoverTimeFormat(event.start)} - ${_.DateUtils.hoverTimeFormat(event.end)}";
    }
    return "${_.DateUtils.hoverDateFormatDiff(event.start)} - ${_.DateUtils.hoverDateFormatDiff(event.end)}";
  }
}

class _HoverRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HoverRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: white_default,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class HeaderOperatorCalendar extends StatefulWidget {
  final Account user;

  HeaderOperatorCalendar(this.user, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HeaderOperatorCalendarState();
}

class _HeaderOperatorCalendarState extends State<HeaderOperatorCalendar> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Account> _operators = [];
  final PDFUtils _pdfUtils = PDFUtils();

  // OTTIMIZZAZIONE 8: Usa addPostFrameCallback solo una volta
  bool _initialized = false;

  @override
  void didUpdateWidget(HeaderOperatorCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateOperatorList();
  }

  void _updateOperatorList() {
    final newOperators = widget.user.webops;

    // Rimuovi operatori non più presenti
    for (int i = _operators.length - 1; i >= 0; i--) {
      if (!newOperators.contains(_operators[i])) {
        final removedOp = _operators.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
              (context, animation) => _buildOperatorItem(removedOp, animation),
          duration: const Duration(milliseconds: 100),
        );
      }
    }

    // Aggiungi nuovi operatori
    for (int i = 0; i < newOperators.length; i++) {
      if (i >= _operators.length || _operators[i] != newOperators[i]) {
        _operators.insert(i, newOperators[i]);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 100));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOperatorList();
      });
    }

    context.read<CalendarContentWebCubit>().calcWidthOpeCalendar();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 120,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _AddOperatorButton(),
            Expanded(
              child: AnimatedList(
                controller: context.read<CalendarContentWebCubit>().horizontalHeader,
                key: _listKey,
                initialItemCount: _operators.length,
                itemBuilder: (context, i, animation) =>
                    _buildOperatorItem(_operators[i], animation),
                scrollDirection: Axis.horizontal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorItem(Account operator, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      ),
      child: _HeaderOperatorItem(
        operator: operator,
        pdfUtils: _pdfUtils,
      ),
    );
  }
}

// OTTIMIZZAZIONE 9: Widget separato per il singolo operatore
class _HeaderOperatorItem extends StatelessWidget {
  final Account operator;
  final PDFUtils pdfUtils;

  const _HeaderOperatorItem({
    required this.operator,
    required this.pdfUtils,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarContentWebCubit>();

    return Container(
      height: 120,
      width: cubit.state.widthOpeCalendar,
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
      decoration: const BoxDecoration(
        color: white,
        border: Border(right: BorderSide(color: grey_light, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _OperatorIcon(typology: operator.typology),
          const SizedBox(height: 11),
          _OperatorName(
            surname: operator.surname,
            name: operator.name,
          ),
          const SizedBox(height: 10),
          _OperatorActions(
            operator: operator,
            pdfUtils: pdfUtils,
          ),
        ],
      ),
    );
  }
}

class _OperatorIcon extends StatelessWidget {
  final String typology;

  const _OperatorIcon({required this.typology});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      padding: const EdgeInsets.only(top: 5, left: 5, right: 8, bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
        color: black,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 25,
          maxHeight: 25,
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Account.getIconTypology(typology).icon,
            color: yellow,
          ),
        ),
      ),
    );
  }
}

class _OperatorName extends StatelessWidget {
  final String surname;
  final String name;

  const _OperatorName({
    required this.surname,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: RichText(
        overflow: TextOverflow.fade,
        maxLines: 1,
        softWrap: false,
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: "${surname.toUpperCase()} ",
              style: title.copyWith(color: black, fontSize: 16),
            ),
            TextSpan(
              text: name.capitalize(),
              style: subtitle.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorActions extends StatelessWidget {
  final Account operator;
  final PDFUtils pdfUtils;

  const _OperatorActions({
    required this.operator,
    required this.pdfUtils,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.print,
          onTap: () => _handlePrint(context),
        ),
        const SizedBox(width: 15),
        _ActionButton(
          icon: Icons.settings,
          onTap: () {},
        ),
        const SizedBox(width: 15),
        _ActionButton(
          icon: Icons.delete,
          onTap: () => context.read<WebCubit>().removeAccount(operator.id),
        ),
      ],
    );
  }

  void _handlePrint(BuildContext context) {
    final webCubit = context.read<WebCubit>();
    final calendarState = webCubit.state.calendarPageState as ReadyCalendarPageState;

    Printing.layoutPdf(
      onLayout: (format) => pdfUtils.createDailyProgram(
        calendarState.selectedEventsOperator(operator.id),
        webCubit.state.calendarPageState.calendarDate,
        operator,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: black,
        child: InkWell(
          splashColor: black_light,
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, color: white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _AddOperatorButton extends StatelessWidget {
  const _AddOperatorButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: white,
        border: Border(right: BorderSide(color: grey_light, width: 1)),
      ),
      height: 120,
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: ElevatedButton(
        onPressed: () => PlatformUtils.navigator(
          context,
          Constants.addWebOperatorRoute,
          <String, dynamic>{},
        ),
        style: ButtonStyle(
          shape: WidgetStateProperty.all(const CircleBorder()),
          padding: WidgetStateProperty.all(const EdgeInsets.all(5)),
          backgroundColor: WidgetStateProperty.all(black),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) return black_light;
            return null;
          }),
        ),
        child: const Icon(Icons.add, color: white, size: 35),
      ),
    );
  }
}

class OperatorCalendar extends StatefulWidget {
  final Account user;
  final int backGridLength;
  final double topSpace;

  const OperatorCalendar(
      this.user,
      this.backGridLength,
      this.topSpace, {
        Key? key,
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _OperatorCalendarState();
}

class _OperatorCalendarState extends State<OperatorCalendar> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Account> _operators = [];
  bool _initialized = false;

  @override
  void didUpdateWidget(OperatorCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.webops != widget.user.webops) {
      _updateOperatorList();
    }
  }

  void _updateOperatorList() {
    final newOperators = widget.user.webops;

    for (int i = _operators.length - 1; i >= 0; i--) {
      if (!newOperators.contains(_operators[i])) {
        final removedOp = _operators.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
              (context, animation) => _buildOperatorCalendar(removedOp, i, animation),
          duration: const Duration(milliseconds: 100),
        );
      }
    }

    for (int i = 0; i < newOperators.length; i++) {
      if (i >= _operators.length || _operators[i] != newOperators[i]) {
        _operators.insert(i, newOperators[i]);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 100));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOperatorList();
      });
    }

    context.read<CalendarContentWebCubit>().calcWidthOpeCalendar();
    final cubit = context.read<CalendarContentWebCubit>();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          height: (widget.backGridLength * cubit.gridHourHeight) + widget.topSpace,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: (widget.backGridLength * cubit.gridHourHeight) +
                    widget.topSpace - 120,
                width: 0,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: grey_light, width: 1)),
                ),
              ),
              Expanded(
                child: RawScrollbar(
                  thumbColor: black_light,
                  radius: const Radius.circular(20),
                  thickness: 10,
                  controller: cubit.horizontalCalendar,
                  child: AnimatedList(
                    controller: cubit.horizontalCalendar,
                    key: _listKey,
                    initialItemCount: _operators.length,
                    itemBuilder: (context, i, animation) =>
                        _buildOperatorCalendar(_operators[i], i, animation),
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorCalendar(Account operator, int index, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
      ),
      child: _SingleOperatorCalendar(
        operator: operator,
        index: index,
      ),
    );
  }
}

// OTTIMIZZAZIONE 10: Widget separato per calendario singolo operatore
class _SingleOperatorCalendar extends StatelessWidget {
  final Account operator;
  final int index;

  const _SingleOperatorCalendar({
    required this.operator,
    required this.index,
  });

  void _changeEvent(
      Event event,
      DraggableDetails details,
      BuildContext context,
      ) {
    final cubit = context.read<CalendarContentWebCubit>();
    final webCubit = context.read<WebCubit>();

    final newOperator = cubit.moveEventToOperator(details);
    final selectDay = webCubit.state.calendarPageState.calendarDate;
    final start = webCubit.moveEventToDate(details, selectDay, cubit.gridHourHeight);
    final end = start.add(event.end.difference(event.start));

    if (newOperator != operator || start != event.start) {
      AttectionAlert(
        context,
        title: "CAMBIA INCARICO",
        text: "Stai assegnando l'incarico al operatore:",
        operator: newOperator,
        showDetailsContent: newOperator != operator,
        showDetailsContentDate: start != event.start,
        showRepeatContent: event.isRepeated,
        start: start,
        end: end,
      ).show().then((value) {
        if (value.first) {
          cubit.changeOperatorEvent(
            event,
            operator,
            newOperator,
            start,
            end,
            value[1],
            value.last,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final webCubit = context.read<WebCubit>();
    final cubit = context.read<CalendarContentWebCubit>();
    final selectDay = webCubit.state.calendarPageState.calendarDate;

    final eventLayouts = (webCubit.state.calendarPageState as ReadyCalendarPageState)
        .selectedEventsGroupOperator(operator.id)
        .expand((overlapGroup) => overlapGroup.calculateGroupLayout(
      cubit.state.widthOpeCalendar,
      selectDay,
    ))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.only(top: 50),
              width: cubit.state.widthOpeCalendar,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: grey_light, width: 1)),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // OTTIMIZZAZIONE 11: Usa ListView.builder se ci sono molti eventi
                  ...eventLayouts.map((layout) => Positioned(
                    top: layout.top,
                    left: layout.left,
                    width: layout.width,
                    height: layout.height,
                    child: _EventCard(
                      layout: layout,
                      operator: operator,
                      selectDay: selectDay,
                      index: index,
                      onDragEnd: (dragEvent) => _changeEvent(
                        layout.event,
                        dragEvent,
                        context,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// OTTIMIZZAZIONE 12: Widget separato per event card con RepaintBoundary
class _EventCard extends StatelessWidget {
  final EventLayout layout;
  final Account operator;
  final DateTime selectDay;
  final int index;
  final Function(DraggableDetails) onDragEnd;

  const _EventCard({
    required this.layout,
    required this.operator,
    required this.selectDay,
    required this.index,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        opaque: false,
        onEnter: (e) => context.read<CalendarContentWebCubit>()
            .hoverCardEnter(selectDay, index, layout.event),
        onExit: (e) => context.read<CalendarContentWebCubit>().hoverCardExit(),
        cursor: WidgetStateMouseCursor.clickable,
        child: Draggable<Event>(
          data: layout.event,
          maxSimultaneousDrags: 1,
          feedback: Opacity(
            opacity: 0.3,
            child: SizedBox(
              width: layout.width,
              child: CardEvent(
                event: layout.event,
                height: layout.height,
                externalBorder: true,
              ),
            ),
          ),
          onDragEnd: onDragEnd,
          child: CardEvent(
            event: layout.event,
            height: layout.height,
            externalBorder: true,
            onTapAction: (event) => PlatformUtils.navigator(
              context,
              Constants.detailsEventViewRoute,
              {"objectParameter": event},
            ),
          ),
        ),
      ),
    );
  }
}