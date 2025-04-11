import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/users_manage/users_manage_cubit.dart';
import 'package:venturiautospurghi/cubit/web/usersManage_page/users_manage_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/dataTable/account_data_table.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/headers_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_delete.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/chart/BadgePieChart.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_account_widget.dart';
import 'package:venturiautospurghi/views/widgets/flat_tab_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';
import 'package:venturiautospurghi/views/widgets/table/pagination_table.dart';

class UsersManage extends StatelessWidget {

  Map<String, dynamic> filters;

  UsersManage({Map<String, dynamic>? filters}) :
        this.filters = filters?? {};

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();

    return new BlocProvider(
        create: (_) => UsersManageCubit(repository, filters),
        child: ResponsiveWidget(
          smallScreen: _smallScreen(),
          largeScreen: _largeScreen(),
        ));
  }
}

void _onDeletePressed(Account account, BuildContext context) async {
  if (await context.read<WebCubit>().usersManagePageCubit.deleteAccount(account))
    await SuccessAlert(context, text: "Utente eliminato!").show();
}

void scrollListener(BuildContext context){
  context.read<UsersManageCubit>().scrollController.addListener(() {
    if (context.read<UsersManageCubit>().scrollController.position.pixels == context.read<UsersManageCubit>().scrollController.position.maxScrollExtent) {
      if(context.read<UsersManageCubit>().canLoadMore)
        context.read<UsersManageCubit>().loadMoreData();
    }
  });
}


class _largeScreen extends StatefulWidget {

  _largeScreen();

  @override
  State<StatefulWidget> createState() => _largeScreenState();

}

class _largeScreenState extends State<_largeScreen>  {

  Future ft = Future(() {});
  Tween<Offset> _offset = Tween(begin: Offset(1,0), end: Offset(0,0));
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Widget> _listHeaderUsers = [];
  List<PieChartSectionData> _listPieSection = [];
  final List<MapEntry<Tab,int>> tabsHeaders = Headers.tabsHeadersUsers;

  _addWidgetHeaderContacts(){
    _listHeaderUsers = [];
    _listKey.currentState?.removeAllItems((context, animation) => Container());
    tabsHeaders.forEach((header) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listHeaderUsers.add(_headerWidget(header));
          _listKey.currentState?.insertItem(_listHeaderUsers.length -1);
        });
      });
    });
  }

  void _listPieChartSectionData(){
    _listPieSection.clear();
    tabsHeaders.forEach((header) {
      if (header.value != 0) {
        _listPieSection.add(_PieChartSectionDataWidget(header));
      }
    });
  }

  Widget _headerWidget(MapEntry<Tab,int> mapEntry){
    return BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) =>
        previous.usersManagePageState.selectedStatusTab != current.usersManagePageState.selectedStatusTab
            || previous.usersManagePageState.countEntity != current.usersManagePageState.countEntity,
        builder: (context, state) {
          return Container(margin: EdgeInsets.symmetric(vertical: 5),child: FlatFab(mapEntry, selectedStatus: state.usersManagePageState.selectedStatusTab,
            onStatusTabSelected: context.read<WebCubit>().usersManagePageCubit.onStatusTabSelected,
            count: (state.usersManagePageState.countEntity[mapEntry.value]??0),)
          );
        });
  }

  PieChartSectionData _PieChartSectionDataWidget(MapEntry<Tab,int> mapEntry){
    bool active = context.read<WebCubit>().state.usersManagePageState.selectedStatusTab == mapEntry.value;
    int tot = context.read<WebCubit>().state.usersManagePageState.countEntity[0]??1;
    int value = context.read<WebCubit>().state.usersManagePageState.countEntity[mapEntry.value]??0;
    int perceptual = DoubleUtils.roundUpIfOverHalf((100 * value) / tot);

    return PieChartSectionData(
      color: Account.getColorTypology(mapEntry.value),
      value: perceptual.toDouble(),
      title: perceptual.toString()+'%',
      radius: active?70:60.0,
      titleStyle: TextStyle(
        fontSize: active?15:13.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
      ),
      badgeWidget: BadgePieChart(
        (mapEntry.key.icon as Icon).icon,
        size: active?35:30.0,
        borderColor: grey_light,
        active: active,
        tooltipText: (mapEntry.key.text??'').toLowerCase().capitalize(),
      ),
      badgePositionPercentageOffset: 0.98,
    );
  }

  void deleteAccount(Account account, BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA UTENTE", text: "Confermi la cancellazione del utente?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().usersManagePageCubit.deleteAccount(account);
      }
    });
  }

  void deleteAllAccount(BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA GLI UTENTI", text: "Confermi la cancellazione degli utenti selezionati?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().usersManagePageCubit.deleteAllAccount();
      }
    });
  }

  Widget gridUsersManage() => Container(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Sidebar con la lista animata
        Container(
          width: 240,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Tipologie", style: title),
              SizedBox(height: 10),
              AnimatedList(
                shrinkWrap: true,
                key: _listKey,
                initialItemCount: _listHeaderUsers.length,
                itemBuilder: (context, i, animation) => SlideTransition(
                  position: animation.drive(_offset),
                  child: _listHeaderUsers[i],
                ),
              ),
              SizedBox(height: 10,),
              Divider(
                color: grey_light2,
                thickness: 1,
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
              SizedBox(height: 10,),
              BlocBuilder<WebCubit, WebCubitState>(
                  buildWhen: (previous, current) =>
                  previous.usersManagePageState.countEntity != current.usersManagePageState.countEntity
                      || previous.usersManagePageState.selectedStatusTab != current.usersManagePageState.selectedStatusTab,
                  builder: (context, state) {
                    _listPieChartSectionData();
                    return Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(
                                mouseCursorResolver: (event, pieTouchResponse) => event is FlPointerHoverEvent?SystemMouseCursors.click:SystemMouseCursors.basic,
                                touchCallback: (event, pieTouchResponse) => event is FlTapDownEvent?context.read<WebCubit>().usersManagePageCubit.onTouchPieChart(event,pieTouchResponse):null
                            ),
                            borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: grey, width: 1)
                            ),
                            sectionsSpace: 5,
                            centerSpaceRadius: 30,
                            sections: _listPieSection,
                          ),
                        ));
                  }),
            ],
          ),
        ),
        // Contenitore principale per la griglia dei clienti
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: [
                    Text("Tutti gli utenti", style: title, textAlign: TextAlign.left),
                    Expanded(child: Container()),
                    BlocBuilder<WebCubit, WebCubitState>(
                        buildWhen: (previous, current) => previous.usersManagePageState.mapSelected != current.usersManagePageState.mapSelected ||
                            previous.usersManagePageState.numPage != current.usersManagePageState.numPage,
                        builder: (context, state) {
                          return AnimatedContainer(
                            curve: Curves.easeInOut,
                            duration: Duration(milliseconds: 500),
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: AnimatedOpacity(
                                opacity: context.read<WebCubit>().usersManagePageCubit.isSelected() ? 1.0 : 0.0, // Opacità cambia a 0
                                duration: Duration(milliseconds: 500),
                                child: ElevatedButton(
                                    style: raisedButtonStyle.copyWith(
                                        padding: WidgetStateProperty.all<EdgeInsets>(
                                            EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),),)),
                                    onPressed: () => deleteAllAccount(context),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(Icons.delete, color: white,),
                                        SizedBox(width: 5),
                                        Text("Cancella tutti", style: subtitle_rev,),
                                      ],
                                    )
                                )),
                          );
                        })
                  ],
                ),
                // Controllo presenza clienti
                if (context.read<WebCubit>().state.usersManagePageState.accountList.isNotEmpty)
                  BlocBuilder<WebCubit, WebCubitState>(
                      buildWhen: (previous, current) => previous.usersManagePageState.mapSelected != current.usersManagePageState.mapSelected ||
                          previous.usersManagePageState.numPage != current.usersManagePageState.numPage,
                      builder: (context, state) {
                        return PaginationTable(new AccountDataTable(context.read<WebCubit>().state.usersManagePageState.accountList,
                            context.read<WebCubit>().state.usersManagePageState.totalEvent,
                                (account) => deleteAccount(account,context),
                                (account) => PlatformUtils.navigator(context, Constants.registerRoute,<String, dynamic>{
                              'objectParameter' : context.read<WebCubit>().usersManagePageCubit.getEventAccount(account),
                              'typeStatus' : TypeStatus.modify, 'context' : context,},),
                            context.read<WebCubit>().usersManagePageCubit.onSelectedAccount,
                            context.read<WebCubit>().state.usersManagePageState.mapSelected
                        ),
                          ['','Nome','Email','Telefono','Codicefiscale','Azioni'],
                          firstRowIndex: state.usersManagePageState.numPage,
                          selectAll: context.read<WebCubit>().usersManagePageCubit.onSelectedAllAccount,
                          handleNext: context.read<WebCubit>().usersManagePageCubit.nextPage,
                          handlePrevious: context.read<WebCubit>().usersManagePageCubit.previousPage,
                        );
                      })
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Nessun utente da mostrare", style: title),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _addWidgetHeaderContacts();
    });
    return BlocBuilder <WebCubit, WebCubitState>(
        buildWhen: (previous, current) => previous.usersManagePageState.accountList != current.usersManagePageState.accountList,
        builder: (context, state) {
          return !(state.usersManagePageState is ReadyUsersManagePageState) ? Center(child: CircularProgressIndicator()) :
            gridUsersManage();
        });
  }

}

class _smallScreen extends StatefulWidget {

  _smallScreen();

  @override
  State<StatefulWidget> createState() => _smallScreenState();

}

class _smallScreenState extends State<_smallScreen> with TickerProviderStateMixin {

  @override
  void initState() {
    scrollListener(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12.0,
      borderRadius: new BorderRadius.only(
          topLeft: new Radius.circular(16.0),
          topRight: new Radius.circular(16.0)),
      child: Column(
        children: [
          SizedBox(height: 15,),
          AccountsFilterWidget(
            hintTextSearch: 'Cerca gli utenti',
            onSearchFieldChanged: context.read<UsersManageCubit>().onFiltersChanged,
            onFiltersChanged: context.read<UsersManageCubit>().onFiltersChanged,
          ),
          BlocBuilder<UsersManageCubit, UsersManageState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return !(state is ReadyUsersManage) ? Center(
                    child: CircularProgressIndicator()) : state.accountList.length > 0 ?
                Expanded(child: Padding(
                    padding: EdgeInsets.all(15.0),
                    child: ListView.separated(
                        controller: context.read<UsersManageCubit>().scrollController,
                        separatorBuilder: (context, index) => SizedBox(height: 10,),
                        physics: BouncingScrollPhysics(),
                        padding: new EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: state.accountList.length+1,
                        itemBuilder: (context, index) => index != state.accountList.length?
                        Container(
                            /*child:CardCustomer(
                              customer:  state.accountList[index],
                              onEditAction: () => PlatformUtils.navigator(context, Constants.registerRoute,<String, dynamic>{
                                'objectParameter' : context.read<UsersManageCubit>().getEventAccount(state.accountList[index]),
                                'typeStatus' : TypeStatus.modify, 'context' : context, 'callback': PlatformUtils.isMobile?context.read<UsersManageCubit>().forceRefresh:null}),
                              onDeleteAction: () => _onDeletePressed(state.accountList[index], context),)*/
                        ) : context.read<UsersManageCubit>().canLoadMore?
                        Center(
                            child: Container(
                              margin: new EdgeInsets.symmetric(vertical: 13.0),
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(),
                            )):Container()
                    ))) : Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(padding: EdgeInsets.only(bottom: 5),
                          child: Text(
                            "Nessun utente da mostrare", style: title,)),
                    ],
                  ),
                );
              })
        ],
      ),);
  }

  @override
  void dispose() {
    context.read<UsersManageCubit>().scrollController.dispose();
    super.dispose();
  }

}