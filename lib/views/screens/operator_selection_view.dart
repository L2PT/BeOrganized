import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/operator_selection/operator_selection_cubit.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_operators_widget.dart';
import 'package:venturiautospurghi/views/widgets/list_tile_operator.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';

class OperatorSelection extends StatelessWidget {
  BuildContext? callerContext;
  Event? event;
  final bool requirePrimaryOperator;

  OperatorSelection([this.event, this.requirePrimaryOperator = false, this.callerContext]);

  @override
  Widget build(BuildContext context) {
    if(callerContext != null) context = callerContext!;
    var repository = context.read<CloudFirestoreService>();
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: new BlocProvider(
          create: (_) => OperatorSelectionCubit(repository, event, requirePrimaryOperator),
          child: _operatorSelectableList()
      ),
    );
  }
}

class _operatorSelectableList extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _operatorSelectableListState();

}

class _operatorSelectableListState extends State<_operatorSelectableList> {

  late ScrollController scrollController;

  @override
  void initState() {
    context.read<OperatorSelectionCubit>().scrollController.addListener(() {
      if (context.read<OperatorSelectionCubit>().scrollController.position.pixels ==
          context.read<OperatorSelectionCubit>().scrollController.position.maxScrollExtent) {
        if(context.read<OperatorSelectionCubit>().canLoadMore)
          context.read<OperatorSelectionCubit>().loadMoreData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    Widget buildOperatorsList() => ListView.separated(
        controller: context.read<OperatorSelectionCubit>().scrollController,
        separatorBuilder: (context, index) =>
            Divider(height: 2, thickness: 1, indent: 15, endIndent: 15, color: grey_light),
        physics: BouncingScrollPhysics(),
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        itemCount: (context.read<OperatorSelectionCubit>().state as ReadyOperators).filteredOperators.length+1,
        itemBuilder: (context, index) => index != (context.read<OperatorSelectionCubit>().state as ReadyOperators).filteredOperators.length?
        new ListTileOperator(
            (context.read<OperatorSelectionCubit>().state as ReadyOperators).filteredOperators[index],
            checkbox: context.read<OperatorSelectionCubit>().isTriState?2:1,
            isChecked: (context.read<OperatorSelectionCubit>().state as ReadyOperators).selectionList[(context.read<OperatorSelectionCubit>().state as ReadyOperators).filteredOperators[index].id]!,
            onTap: context.read<OperatorSelectionCubit>().onTap) :
        context.read<OperatorSelectionCubit>().canLoadMore? Center(
            child: Container(
              margin: new EdgeInsets.symmetric(vertical: 13.0),
              height: 26,
              width: 26,
              child: CircularProgressIndicator(),
            )):Container()
    );
    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    return Scaffold(
        appBar: AppBar(
            title: Text('OPERATORI LIBERI',style: title_rev,),
            leading: IconButton(icon:Icon(Icons.arrow_back, color: white),
              onPressed: () => onExit(false,event: context.read<OperatorSelectionCubit>().getEvent())
            ),
          actions: [
            Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(15.0),
            child: ElevatedButton(
              child: new Text('CONFERMA', style: subtitle_rev),
              style: raisedButtonStyle.copyWith(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))),
              ),
              onPressed: (){
                if(context.read<OperatorSelectionCubit>().validateAndSave())
                  onExit(true,event: context.read<OperatorSelectionCubit>().getEvent());
              },
            )),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BlocBuilder<OperatorSelectionCubit, OperatorSelectionState>(builder: (context, state) {
              return OperatorsFilterWidget(
                paddingTop: 10,
                hintTextSearch: "Cerca un operatore",
                onSearchFieldChanged: context.read<OperatorSelectionCubit>().onSearchFieldChanged,
                onFiltersChanged: context.read<OperatorSelectionCubit>().onFiltersChanged,
                isExpandable: false,
              );
            }),
            Padding(padding: EdgeInsets.only(left: 20, top: 10), child: Text("Scegli tra gli operatori disponibili", style: label,)),
            BlocBuilder<OperatorSelectionCubit, OperatorSelectionState>(
              buildWhen: (previous, current) => true,
              builder: (context, state) {
                return Expanded(
                  child: (state is ReadyOperators)?
                      buildOperatorsList():
                  LoadingScreen()
                );
              })
          ]
        )
    );
  }

  @override
  void didChangeDependencies() {
    scrollController = context.read<OperatorSelectionCubit>().scrollController;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

}

