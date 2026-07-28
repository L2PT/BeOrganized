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
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

import '../../models/address.dart';
import '../../models/customer.dart';
import '../../models/referrals.dart';
import 'create_address_view.dart';
import 'create_referrals_view.dart';

class CustomerSelection extends StatelessWidget {
  final Event? event;
  final CloudFirestoreService? repository;
  final bool isSlidePanel;
  final void Function(dynamic)? onConfirm;
  final VoidCallback? onClose;

  const CustomerSelection([this.event, this.repository])
      : isSlidePanel = false,
        onConfirm = null,
        onClose = null;

  const CustomerSelection.slidePanel({
    super.key,
    required this.event,
    required this.onConfirm,
    required this.onClose,
    this.repository,
  }) : isSlidePanel = true;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? context.read<CloudFirestoreService>();
    if (isSlidePanel) {
      return BlocProvider(
        create: (_) => CustomerSelectionCubit(repo, event),
        child: _customerSelectableList(isSlidePanel: true, onConfirm: onConfirm, onClose: onClose),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: BlocProvider(
        create: (_) => CustomerSelectionCubit(repo, event),
        child: const _customerSelectableList(isSlidePanel: false),
      ),
    );
  }
}

class _customerSelectableList extends StatefulWidget {
  final bool isSlidePanel;
  final void Function(dynamic)? onConfirm;
  final VoidCallback? onClose;

  const _customerSelectableList({
    required this.isSlidePanel,
    this.onConfirm,
    this.onClose,
  });

  @override
  State<StatefulWidget> createState() => _customerSelectableListState();
}

class _customerSelectableListState extends State<_customerSelectableList> {

  late ScrollController scrollController;
  int _tabIndex = 0;

  void _showAddressDialog(BuildContext context, CustomerSelectionCubit selectionCubit, Customer customer, {Address? address}) {
    final isModify = address != null;
    final event = selectionCubit.getEventCustomer(customer);
    if (isModify) {
      event.customer.address = address;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: whitebackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: CreateAddress.slidePanel(
              event: event,
              type: isModify ? TypeStatus.modify : TypeStatus.create,
              repository: context.read<CloudFirestoreService>(),
              onConfirm: (newAddress) {
                Navigator.pop(dialogContext);
                selectionCubit.forceRefresh();
              },
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  void _showReferralDialog(BuildContext context, CustomerSelectionCubit selectionCubit, Customer customer, {Referrals? referral}) {
    final isModify = referral != null;
    final event = selectionCubit.getEventCustomer(customer);
    if (isModify) {
      event.customer.referral = referral;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: whitebackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: CreateReferrals.slidePanel(
              event: event,
              type: isModify ? TypeStatus.modify : TypeStatus.create,
              repository: context.read<CloudFirestoreService>(),
              onConfirm: (newReferral) {
                Navigator.pop(dialogContext);
                selectionCubit.forceRefresh();
              },
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
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

    void _onCerateCustomer(){
        PlatformUtils.navigator(context, Constants.createCustomerViewRoute,
            <String, dynamic>{'objectParameter' : context.read<CustomerSelectionCubit>().getEventCustomerEmpty(),
              'typeStatus' : TypeStatus.create, 'context' : context, 'callback': context.read<CustomerSelectionCubit>().forceRefresh});
    }

    void _onDeletePressed(Customer customer) async {
      if (await context.read<CustomerSelectionCubit>().deleteCustomer(customer))
        await SuccessAlert(context, text: "Cliente eliminato!").show();
    }

    Widget buildCustomersList() => context.read<CustomerSelectionCubit>().state.filteredCustomers.isNotEmpty?
        ListView.separated(
            controller: context.read<CustomerSelectionCubit>().scrollController,
            separatorBuilder: (context, index) => const SizedBox(height: 5,),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers.length+1,
            itemBuilder: (context, index) => index != (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers.length?
            CardCustomer(
              key: ValueKey((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index].id),
              controller: context.read<CustomerSelectionCubit>().getController((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index].id),
              expadedMode: context.read<CustomerSelectionCubit>().getExpadedMode((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
              customer:  (context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index],
              selectedMode: context.read<CustomerSelectionCubit>().getExpadedMode((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
              onEditAction: () => PlatformUtils.navigator(context, Constants.createCustomerViewRoute,<String, dynamic>{
                'objectParameter' : context.read<CustomerSelectionCubit>().getEventCustomer((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
                'typeStatus' : TypeStatus.modify, 'context' : context, 'callback': context.read<CustomerSelectionCubit>().forceRefresh}),
              onExpansionChanged: context.read<CustomerSelectionCubit>().onExpansionChanged,
              onDeleteAction: () => _onDeletePressed((context.read<CustomerSelectionCubit>().state as ReadyCustomers).filteredCustomers[index]),
              onTapActionAddress: context.read<CustomerSelectionCubit>().selectAddressOnCustomer,
              onDeleteActionAddress: context.read<CustomerSelectionCubit>().removeAddressOnCustomer,
              onEditActionAddress: (address) {
                var cubit = context.read<CustomerSelectionCubit>();
                cubit.selectAddressOnCustomer(address);
                if (PlatformUtils.isMobile) {
                  PlatformUtils.navigator(context, Constants.createAddressViewRoute, <String, dynamic>{
                    'objectParameter' : cubit.getEventCustomer((cubit.state as ReadyCustomers).filteredCustomers[index]),
                    'typeStatus' : TypeStatus.modify,
                    'context' : context,
                    'callback': cubit.forceRefresh
                  });
                } else {
                  _showAddressDialog(context, cubit, (cubit.state as ReadyCustomers).filteredCustomers[index], address: address);
                }
              },
              onCreateActionAddress: () {
                var cubit = context.read<CustomerSelectionCubit>();
                if (PlatformUtils.isMobile) {
                  PlatformUtils.navigator(context, Constants.createAddressViewRoute, <String, dynamic>{
                    'objectParameter' : cubit.getEventCustomer((cubit.state as ReadyCustomers).filteredCustomers[index]),
                    'typeStatus' : TypeStatus.create,
                    'context' : context,
                    'callback': cubit.forceRefresh
                  });
                } else {
                  _showAddressDialog(context, cubit, (cubit.state as ReadyCustomers).filteredCustomers[index]);
                }
              },
              onDeleteActionReferrals: context.read<CustomerSelectionCubit>().removeReferralOnCustomer,
              onEditActionReferrals: (referrals) {
                var cubit = context.read<CustomerSelectionCubit>();
                var customer = (cubit.state as ReadyCustomers).filteredCustomers[index];
                if (PlatformUtils.isMobile) {
                  customer.referral = referrals;
                  PlatformUtils.navigator(context, Constants.createReferralsViewRoute, <String, dynamic>{
                    'objectParameter' : cubit.getEventCustomer(customer),
                    'typeStatus' : TypeStatus.modify,
                    'context' : context,
                    'callback': cubit.forceRefresh
                  });
                } else {
                  _showReferralDialog(context, cubit, customer, referral: referrals);
                }
              },
              onCreateActionReferrals: () {
                var cubit = context.read<CustomerSelectionCubit>();
                if (PlatformUtils.isMobile) {
                  PlatformUtils.navigator(context, Constants.createReferralsViewRoute, <String, dynamic>{
                    'objectParameter' : cubit.getEventCustomer((cubit.state as ReadyCustomers).filteredCustomers[index]),
                    'typeStatus' : TypeStatus.create,
                    'context' : context,
                    'callback': cubit.forceRefresh
                  });
                } else {
                  _showReferralDialog(context, cubit, (cubit.state as ReadyCustomers).filteredCustomers[index]);
                }
              },
              onTapActionReferrals: context.read<CustomerSelectionCubit>().selectReferralsOnCustomer,
            ):
            context.read<CustomerSelectionCubit>().state.canLoadMore?
            Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 13.0), height: 26, width: 26,
              child: const CircularProgressIndicator(),)):Container()
        ):Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Nessun cliente da mostrare", style: title),
              ],
            ),
          ),
        );

    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    final cubit = context.read<CustomerSelectionCubit>();

    Widget buildBodyContent() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BlocBuilder<CustomerSelectionCubit, CustomerSelectionState>(builder: (context, state) {
              return CustomersFilterWidget(
                paddingTop: 10,
                hintTextSearch: "Cerca un cliente",
                onSearchFieldChanged: cubit.onSearchFieldChanged,
                onFiltersChanged: cubit.onFiltersChanged,
                isExpandable: false,
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  onTap: (index) {
                    setState(() {
                      _tabIndex = index;
                    });
                    String typology;
                    if (index == 0) typology = Customer.ALL;
                    else if (index == 1) typology = Customer.AZIENDA;
                    else if (index == 2) typology = Customer.PRIVATO;
                    else if (index == 3) typology = Customer.REFERENTE;
                    else typology = Customer.AMMINISTRATORE;
                    cubit.onTypologyChanged(typology);
                  },
                  labelColor: yellow,
                  unselectedLabelColor: grey_dark,
                  indicatorColor: yellow,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: "TUTTI"),
                    Tab(text: "AZIENDA"),
                    Tab(text: "PRIVATO"),
                    Tab(text: "REFERENTE"),
                    Tab(text: "AMMINISTRATORE"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tabIndex == 0
                        ? "TUTTI I CLIENTI"
                        : _tabIndex == 1
                            ? "AZIENDE"
                            : _tabIndex == 2
                                ? "PRIVATI"
                                : _tabIndex == 3
                                    ? "REFERENTI"
                                    : "AMMINISTRATORI",
                    style: label.copyWith(fontSize: 10, color: grey_dark, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: white),
                    label: const Text('Aggiungi', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: black,
                      side: const BorderSide(color: black, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _onCerateCustomer(),
                  ),
                ],
              ),
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
      );
    }

    if (widget.isSlidePanel) {
      return DefaultTabController(
        length: 5,
        initialIndex: _tabIndex,
        child: PanelLayout(
          width: 400,
          icon: Icons.business_outlined,
          title: 'CLIENTI',
          onClose: widget.onClose!,
          onCancel: widget.onClose!,
          onConfirm: () {
            if (cubit.validateAndSave(context)) {
              widget.onConfirm!(cubit.getEvent());
            }
          },
          body: buildBodyContent(),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      initialIndex: _tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text('CLIENTI', style: title_rev),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: white),
            onPressed: () => onExit(false, event: cubit.getEventCustomerEmpty()),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => onExit(false, event: cubit.getEventCustomerEmpty()),
                  child: const Text('ANNULLA', style: TextStyle(color: black, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (cubit.validateAndSave(context)) {
                      onExit(true, event: cubit.getEvent());
                    }
                  },
                  child: const Text('CONFERMA', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        body: buildBodyContent(),
      ),
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
