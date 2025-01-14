import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/customer_selection/customer_selection_cubit.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/card_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';

import '../../models/customer.dart';

class CustomerSelection extends StatelessWidget {
  BuildContext? callerContext;
  Event? event;

  CustomerSelection([this.event, this.callerContext]);

  @override
  Widget build(BuildContext context) {
    if(callerContext != null) context = callerContext!;
    var repository = context.read<CloudFirestoreService>();
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: new BlocProvider(
          create: (_) => CustomerSelectionCubit(repository, event),
          child: _customerSelectableList()
      ),
    );
  }
}

class _customerSelectableList extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _customerSelectableListState();

}

class _customerSelectableListState extends State<_customerSelectableList> {

  late ScrollController scrollController;

  @override
  void initState() {
    context.read<CustomerSelectionCubit>().scrollController.addListener(() {
      if (context.read<CustomerSelectionCubit>().scrollController.position.pixels ==
          context.read<CustomerSelectionCubit>().scrollController.position.maxScrollExtent) {
        if(context.read<CustomerSelectionCubit>().state.canLoadMore)
          context.read<CustomerSelectionCubit>().loadMoreData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    void _onDeletePressed(Customer customer) async {
      if (await context.read<CustomerSelectionCubit>().deleteCustomer(customer))
        await SuccessAlert(context, text: "Cliente eliminato!").show();
    }

    Widget buildCustomersList() => ListView.separated(
        controller: context.read<CustomerSelectionCubit>().scrollController,
        separatorBuilder: (context, index) => SizedBox(height: 10,),
        physics: BouncingScrollPhysics(),
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        itemCount: (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers.length+1,
        itemBuilder: (context, index) => index != (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers.length?
             CardCustomer(
               controller: context.read<CustomerSelectionCubit>().getController((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index].id),
               expadedMode: context.read<CustomerSelectionCubit>().getExpadedMode((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
               customer:  (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index],
               selectedMode: context.read<CustomerSelectionCubit>().getExpadedMode((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
               onEditAction: () => PlatformUtils.navigator(context, Constants.createCustomerViewRoute,<String, dynamic>{
                'objectParameter' : context.read<CustomerSelectionCubit>().getEventCustomer((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
                'typeStatus' : TypeStatus.modify}),
               onExpansionChanged: context.read<CustomerSelectionCubit>().onExpansionChanged,
               onDeleteAction: () => _onDeletePressed((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
               onTapActionAddress: context.read<CustomerSelectionCubit>().selectAddressOnCustomer,
               onDeleteActionAddress: context.read<CustomerSelectionCubit>().removeAddressOnCustomer,
               onEditActionAddress: () => PlatformUtils.navigator(context, Constants.createAddressViewRoute, <String, dynamic>{'objectParameter' : context.read<CustomerSelectionCubit>().getEventCustomer((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
                 'typeStatus' : TypeStatus.modify}),

             ):
          context.read<CustomerSelectionCubit>().state.canLoadMore?
            Center(child: Container(margin: new EdgeInsets.symmetric(vertical: 13.0), height: 26, width: 26,
              child: CircularProgressIndicator(),)):Container()
    );

    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('CLIENTI',style: title_rev,),
          leading: IconButton(icon:Icon(Icons.arrow_back, color: white),
              onPressed: () => onExit(false,event: context.read<CustomerSelectionCubit>().getEventCustomerEmpty())
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
                    if(context.read<CustomerSelectionCubit>().validateAndSave())
                      onExit(true,event: context.read<CustomerSelectionCubit>().getEvent());
                  },
                )),
          ],
        ),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              BlocBuilder<CustomerSelectionCubit, CustomerSelectionState>(builder: (context, state) {
                return CustomersFilterWidget(
                  paddingTop: 10,
                  hintTextSearch: "Cerca un cliente",
                  onSearchFieldChanged: context.read<CustomerSelectionCubit>().onSearchFieldChanged,
                  onFiltersChanged: context.read<CustomerSelectionCubit>().onFiltersChanged,
                  isExpandable: false,
                );
              }),
              Row(
                children: [
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(left: 20),
                      child:   Text("Tutti i clienti", style: label.copyWith(fontWeight: FontWeight.bold),),
                    ),
                  ),
                  Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(15.0),
                      child: ElevatedButton(
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: white,),
                            SizedBox(width: 5,),
                            Text('Aggiungi', style: subtitle_rev),
                          ],
                        ),
                        style: raisedButtonStyle.copyWith(shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))),),
                        onPressed: () {
                          PlatformUtils.navigator(context, Constants.createCustomerViewRoute,<String, dynamic>{'objectParameter' : context.read<CustomerSelectionCubit>().getEvent(), 'typeStatus' : TypeStatus.create});
                        },
                      )),
                ],
              ),
              BlocBuilder<CustomerSelectionCubit, CustomerSelectionState>(
                  buildWhen: (previous, current) => previous != current,
                  builder: (context, state) {
                    return Expanded(
                        child: (state is ReadyCustomers)?
                        buildCustomersList():
                        LoadingScreen()
                    );
                  })
            ]
        )
    );
  }

  @override
  void didChangeDependencies() {
    scrollController = context.read<CustomerSelectionCubit>().scrollController;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

}

