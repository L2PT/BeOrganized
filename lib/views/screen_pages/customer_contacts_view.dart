import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/customer_contacts/customer_contacts_cubit.dart';
import 'package:venturiautospurghi/cubit/web/contacts_page/contacts_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/dataTable/customer_data_table.dart';
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
import 'package:venturiautospurghi/views/widgets/card_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/chart/BadgePieChart.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/flat_tab_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';
import 'package:venturiautospurghi/views/widgets/table/pagination_table.dart';

class CustomerContacts extends StatelessWidget {

  Map<String, dynamic> filters;

  CustomerContacts({Map<String, dynamic>? filters}) :
        this.filters = filters?? {};

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();

    return new BlocProvider(
        create: (_) => CustomerContactsCubit(repository, filters),
        child: ResponsiveWidget(
          smallScreen: _smallScreen(),
          largeScreen: _largeScreen(),
        ));
  }
}

void _onDeletePressed(Customer customer, BuildContext context) async {
  if (await context.read<WebCubit>().contactsPageCubit.deleteCustomer(customer))
    await SuccessAlert(context, text: "Cliente eliminato!").show();
}

void scrollListener(BuildContext context){
  context.read<CustomerContactsCubit>().scrollController.addListener(() {
    if (context.read<CustomerContactsCubit>().scrollController.position.pixels == context.read<CustomerContactsCubit>().scrollController.position.maxScrollExtent) {
      if(context.read<CustomerContactsCubit>().canLoadMore)
        context.read<CustomerContactsCubit>().loadMoreData();
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
  List<Widget> _listHeaderContacts = [];
  List<PieChartSectionData> _listPieSection = [];
  final List<MapEntry<Tab,int>> tabsHeaders = Headers.tabsHeadersContacts;

  _addWidgetHeaderContacts(){
    _listHeaderContacts = [];
    _listKey.currentState?.removeAllItems((context, animation) => Container());
    tabsHeaders.forEach((header) {
      ft = ft.then((_) {
        return Future.delayed(const Duration(milliseconds: 100), () {
          _listHeaderContacts.add(_headerWidget(header));
          _listKey.currentState?.insertItem(_listHeaderContacts.length -1);
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
    return BlocBuilder<
        WebCubit, WebCubitState>(
        buildWhen: (previous, current) =>
        previous.contactsPageState.selectedStatusTab != current.contactsPageState.selectedStatusTab
            || previous.contactsPageState.countEntity != current.contactsPageState.countEntity,
        builder: (context, state) {
           return Container(margin: EdgeInsets.symmetric(vertical: 5),child: FlatFab(mapEntry, selectedStatus: state.contactsPageState.selectedStatusTab,
             onStatusTabSelected: context.read<WebCubit>().contactsPageCubit.onStatusTabSelected,
             count: (state.contactsPageState.countEntity[mapEntry.value]??0),)
      );
    });
  }

  PieChartSectionData _PieChartSectionDataWidget(MapEntry<Tab,int> mapEntry){
    bool active = context.read<WebCubit>().state.contactsPageState.selectedStatusTab == mapEntry.value;
    int tot = context.read<WebCubit>().state.contactsPageState.countEntity[0]??1;
    int value = context.read<WebCubit>().state.contactsPageState.countEntity[mapEntry.value]??0;
    int perceptual = DoubleUtils.roundUpIfOverHalf((100 * value) / tot);

    return PieChartSectionData(
      color: Customer.getColorTypology(mapEntry.value),
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

  void deleteCustomer(Customer customer, BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA CLIENTE", text: "Confermi la cancellazione del cliente?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().contactsPageCubit.deleteCustomer(customer);
      }
    });
  }

  void deleteAllCustomer(BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA I CLIENTI", text: "Confermi la cancellazione dei clienti selezionati?").show().then((value) {
      if(value.first){
        context.read<WebCubit>().contactsPageCubit.deleteAllCustomer();
      }
    });
  }

  Widget gridContactsCustomer() => Container(
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
                initialItemCount: _listHeaderContacts.length,
                itemBuilder: (context, i, animation) => SlideTransition(
                  position: animation.drive(_offset),
                  child: _listHeaderContacts[i],
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
                previous.contactsPageState.countEntity != current.contactsPageState.countEntity
                  || previous.contactsPageState.selectedStatusTab != current.contactsPageState.selectedStatusTab,
                builder: (context, state) {
                  _listPieChartSectionData();
                  return Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                              mouseCursorResolver: (event, pieTouchResponse) => event is FlPointerHoverEvent?SystemMouseCursors.click:SystemMouseCursors.basic,
                              touchCallback: (event, pieTouchResponse) => event is FlTapDownEvent?context.read<WebCubit>().contactsPageCubit.onTouchPieChart(event,pieTouchResponse):null
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
                    Text("Tutti i clienti", style: title, textAlign: TextAlign.left),
                    Expanded(child: Container()),
                    BlocBuilder<WebCubit, WebCubitState>(
                      buildWhen: (previous, current) => previous.contactsPageState.mapSelected != current.contactsPageState.mapSelected ||
                      previous.contactsPageState.numPage != current.contactsPageState.numPage,
                      builder: (context, state) {
                        return AnimatedContainer(
                          curve: Curves.easeInOut,
                          duration: Duration(milliseconds: 500),
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: AnimatedOpacity(
                              opacity: context.read<WebCubit>().contactsPageCubit.isSelected() ? 1.0 : 0.0, // Opacità cambia a 0
                              duration: Duration(milliseconds: 500),
                              child: ElevatedButton(
                                  style: raisedButtonStyle.copyWith(
                                      padding: WidgetStateProperty.all<EdgeInsets>(
                                          EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),),)),
                                  onPressed: () => deleteAllCustomer(context),
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
                if (context.read<WebCubit>().state.contactsPageState.customerList.isNotEmpty)
                  BlocBuilder<WebCubit, WebCubitState>(
                  buildWhen: (previous, current) => previous.contactsPageState.mapSelected != current.contactsPageState.mapSelected ||
                      previous.contactsPageState.numPage != current.contactsPageState.numPage,
                  builder: (context, state) {
                    return PaginationTable(new CustomerDataTable(context.read<WebCubit>().state.contactsPageState.customerList,
                        context.read<WebCubit>().state.contactsPageState.totalEvent,
                        (customer) => deleteCustomer(customer,context),
                        (customer) => PlatformUtils.navigator(context, Constants.createCustomerViewRoute,<String, dynamic>{
                          'objectParameter' : context.read<WebCubit>().contactsPageCubit.getEventCustomer(customer),
                          'typeStatus' : TypeStatus.modify},),
                        context.read<WebCubit>().contactsPageCubit.onSelectedCustomer,
                        context.read<WebCubit>().state.contactsPageState.mapSelected
                    ),
                        ['','Nome','Email','Indirizzo','Telefoni','Azioni'],
                      firstRowIndex: state.contactsPageState.numPage,
                      selectAll: context.read<WebCubit>().contactsPageCubit.onSelectedAllCustomer,
                      handleNext: context.read<WebCubit>().contactsPageCubit.nextPage,
                      handlePrevious: context.read<WebCubit>().contactsPageCubit.previousPage,
                    );
                  })
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Nessun cliente da mostrare", style: title),
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
        buildWhen: (previous, current) => previous.contactsPageState.customerList != current.contactsPageState.customerList,
        builder: (context, state) {
          return !(state.contactsPageState is ReadyContactsPageState) ? Center(child: CircularProgressIndicator()) :
              gridContactsCustomer();
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
          CustomersFilterWidget(
            hintTextSearch: 'Cerca i clienti',
            onSearchFieldChanged: context.read<CustomerContactsCubit>().onFiltersChanged,
            onFiltersChanged: context.read<CustomerContactsCubit>().onFiltersChanged,
          ),
          BlocBuilder<CustomerContactsCubit, CustomerContactsState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
                return !(state is ReadyCustomerContacts) ? Center(
                    child: CircularProgressIndicator()) : state.customerList.length > 0 ?
                Expanded(child: Padding(
                    padding: EdgeInsets.all(15.0),
                    child: ListView.separated(
                        controller: context.read<CustomerContactsCubit>().scrollController,
                        separatorBuilder: (context, index) => SizedBox(height: 10,),
                        physics: BouncingScrollPhysics(),
                        padding: new EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: state.customerList.length+1,
                        itemBuilder: (context, index) => index != state.customerList.length?
                        Container(
                            child: CardCustomer(
                                customer:  state.customerList[index],
                                onEditAction: () => PlatformUtils.navigator(context, Constants.createCustomerViewRoute,<String, dynamic>{
                                  'objectParameter' : context.read<CustomerContactsCubit>().getEventCustomer(state.customerList[index]),
                                  'typeStatus' : TypeStatus.modify}),
                                onDeleteAction: () => _onDeletePressed(state.customerList[index], context),)
                        ) : context.read<CustomerContactsCubit>().canLoadMore?
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
                            "Nessun cliente da mostrare", style: title,)),
                    ],
                  ),
                );
              })
        ],
      ),);
  }

  @override
  void dispose() {
    context.read<CustomerContactsCubit>().scrollController.dispose();
    super.dispose();
  }

}