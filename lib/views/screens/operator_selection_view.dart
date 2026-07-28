import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/cubit/operator_selection/operator_selection_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_operators_widget.dart';
import 'package:venturiautospurghi/views/widgets/list_tile_operator.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

class OperatorSelection extends StatelessWidget {
  final BuildContext? callerContext;
  final Event? event;
  final bool requirePrimaryOperator;
  final bool isSlidePanel;
  final void Function(dynamic)? onConfirm;
  final VoidCallback? onClose;
  final String title;

  OperatorSelection([
    this.event,
    this.requirePrimaryOperator = false,
    this.callerContext,
    this.title = 'OPERATORI',
  ]) : isSlidePanel = false,
       onConfirm = null,
       onClose = null,
       super(key: null);

  const OperatorSelection.slidePanel({
    super.key,
    required this.event,
    required this.onConfirm,
    required this.onClose,
    this.title = 'SELEZIONA OPERATORI',
  }) : requirePrimaryOperator = true,
       callerContext = null,
       isSlidePanel = true;

  @override
  Widget build(BuildContext context) {
    if (callerContext != null) context = callerContext!;
    var repository = context.read<CloudFirestoreService>();

    final body = BlocProvider(
      create: (_) => OperatorSelectionCubit(repository, event, requirePrimaryOperator),
      child: _OperatorSelectionBody(
        isSlidePanel: isSlidePanel,
        onConfirm: onConfirm,
        onClose: onClose,
        title: title,
      ),
    );

    if (isSlidePanel) {
      return body;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: body,
    );
  }
}

class _OperatorSelectionBody extends StatefulWidget {
  final bool isSlidePanel;
  final void Function(dynamic)? onConfirm;
  final VoidCallback? onClose;
  final String title;

  const _OperatorSelectionBody({
    super.key,
    required this.isSlidePanel,
    required this.title,
    this.onConfirm,
    this.onClose,
  });

  @override
  State<_OperatorSelectionBody> createState() => _OperatorSelectionBodyState();
}

class _OperatorSelectionBodyState extends State<_OperatorSelectionBody> {
  late ScrollController scrollController;
  bool _listenerAttached = false;
  int _tabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAttached) {
      scrollController = context.read<OperatorSelectionCubit>().scrollController;
      scrollController.addListener(_scrollListener);
      _listenerAttached = true;
    }
  }

  void _scrollListener() {
    final cubit = context.read<OperatorSelectionCubit>();
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (cubit.canLoadMore) {
        cubit.loadMoreData();
      }
    }
  }

  @override
  void dispose() {
    if (_listenerAttached) {
      scrollController.removeListener(_scrollListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OperatorSelectionCubit>();

    Widget buildOperatorsList(ReadyOperators state) => ListView.separated(
      controller: scrollController,
      separatorBuilder: (context, index) => Divider(
        height: widget.isSlidePanel ? 1 : 2,
        thickness: 1,
        indent: widget.isSlidePanel ? 14 : 15,
        endIndent: widget.isSlidePanel ? 14 : 15,
        color: grey_light,
      ),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: widget.isSlidePanel ? 6.0 : 8.0),
      itemCount: state.filteredOperators.length + 1,
      itemBuilder: (context, index) {
        if (index == state.filteredOperators.length) {
          return cubit.canLoadMore
              ? (widget.isSlidePanel
                  ? loadingTile()
                  : Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 13.0),
                        height: 26,
                        width: 26,
                        child: const CircularProgressIndicator(),
                      ),
                    ))
              : const SizedBox.shrink();
        }
        final op = state.filteredOperators[index];
        return ListTileOperator(
          op,
          checkbox: cubit.isTriState ? 2 : 1,
          isChecked: state.selectionList[op.id]!,
          onTapPrimary: () => cubit.onTapPrimary(op),
          onTapSecondary: () => cubit.onTapSecondary(op),
          onTap: cubit.onTap,
        );
      },
    );

    Widget buildBodyContent() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        BlocBuilder<OperatorSelectionCubit, OperatorSelectionState>(
          builder: (context, state) {
            return OperatorsFilterWidget(
              paddingTop: 10,
              hintTextSearch: "Cerca un operatore",
              onSearchFieldChanged: cubit.onSearchFieldChanged,
              onFiltersChanged: cubit.onFiltersChanged,
              isExpandable: false,
            );
          },
        ),
        DefaultTabController(
          length: 3,
          initialIndex: _tabIndex,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _tabIndex = index;
                });
                String typology;
                if (index == 0) typology = Account.ALL;
                else if (index == 1) typology = Account.OPERATORE;
                else typology = Account.VEICOLO;
                cubit.onTypologyChanged(typology);
              },
              labelColor: yellow,
              unselectedLabelColor: grey_dark,
              indicatorColor: yellow,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              tabs: const [
                Tab(text: "TUTTI"),
                Tab(text: "OPERATORE"),
                Tab(text: "VEICOLO"),
              ],
            ),
          ),
        ),
        widget.isSlidePanel?Padding(
          padding: widget.isSlidePanel
              ? const EdgeInsets.fromLTRB(16, 12, 16, 4)
              : const EdgeInsets.only(left: 20, top: 12, bottom: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Scegli tra gli operatori disponibili",
              style: widget.isSlidePanel
                  ? const TextStyle(fontSize: 11, color: grey_dark)
                  : label,
            ),
          ),
        ):const SizedBox.shrink(),
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "NOMINATIVO",
                  style: label.copyWith(fontSize: 10, color: grey_dark, fontWeight: FontWeight.bold),
                ),
              ),
              if (cubit.isTriState) ...[
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    "PRINC.",
                    style: label.copyWith(fontSize: 10, color: grey_dark, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  "SEC.",
                  style: label.copyWith(fontSize: 10, color: grey_dark, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        BlocBuilder<OperatorSelectionCubit, OperatorSelectionState>(
          buildWhen: (previous, current) => true,
          builder: (context, state) {
            return Expanded(
              child: (state is ReadyOperators)
                  ? buildOperatorsList(state)
                  : LoadingScreen(),
            );
          },
        ),
      ],
    );

    if (widget.isSlidePanel) {
      return PanelLayout(
        width: 360,
        icon: FontAwesomeIcons.helmetSafety,
        title: widget.title,
        onClose: widget.onClose!,
        onCancel: widget.onClose!,
        onConfirm: () {
          if (cubit.validateAndSave(context)) {
            widget.onConfirm!(cubit.getEvent());
          }
        },
        body: buildBodyContent(),
      );
    }

    void onExit(bool result, {dynamic event}) {
      PlatformUtils.backNavigator(context, <String, dynamic>{'objectParameter': event, 'res': result});
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: title_rev),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: white),
          onPressed: () => onExit(false, event: cubit.getEvent()),
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton(
              style: raisedButtonStyle.copyWith(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              child: Text('CONFERMA', style: subtitle_rev),
              onPressed: () {
                if (cubit.validateAndSave(context)) {
                  onExit(true, event: cubit.getEvent());
                }
              },
            ),
          ),
        ],
      ),
      body: buildBodyContent(),
    );
  }
}
