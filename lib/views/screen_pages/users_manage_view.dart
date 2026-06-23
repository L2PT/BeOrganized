import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/users_manage/users_manage_cubit.dart';
import 'package:venturiautospurghi/cubit/web/usersManage_page/users_manage_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/headers_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_delete.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_account_widget.dart';
import 'package:venturiautospurghi/views/widgets/flat_tab_widget.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';

class UsersManage extends StatefulWidget {

  final Map<String, dynamic> filters;

  UsersManage({Map<String, dynamic>? filters}) :
        this.filters = filters?? {};

  @override
  _UsersManageState createState() => _UsersManageState();
}

class _UsersManageState extends State<UsersManage> {

  @override
  void initState() {
    super.initState();
    if(!PlatformUtils.isMobile) {
      context.read<WebCubit>().initCubit(Constants.manageUtenzeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repository = context.read<CloudFirestoreService>();

    return new BlocProvider(
        create: (_) => UsersManageCubit(repository, widget.filters),
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

  final List<MapEntry<Tab,int>> tabsHeaders = Headers.tabsHeadersUsers;

  Widget _headerWidget(MapEntry<Tab,int> mapEntry){
    return BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) =>
        previous.usersManagePageState.selectedStatusTab != current.usersManagePageState.selectedStatusTab
            || previous.usersManagePageState.countEntity != current.usersManagePageState.countEntity,
        builder: (context, state) {
          return Container(margin: EdgeInsets.symmetric(vertical: 5),child: FlatFab(mapEntry, selectedStatus: state.usersManagePageState.selectedStatusTab,
            onStatusTabSelected: context.read<WebCubit>().usersManagePageCubit.onStatusTabSelected,
            count: (state.usersManagePageState.countEntity[mapEntry.value]??0), horizontalMode: true,)
          );
        });
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

  Widget gridUsersManage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Tutti Gli Operatori Registrati", style: title, textAlign: TextAlign.left),
          ],
        ),
        SizedBox(height: 10),
        Container(
          height: 60,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabsHeaders.map((header) => Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: _headerWidget(header),
              )).toList(),
            ),
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: BlocBuilder<WebCubit, WebCubitState>(
            buildWhen: (previous, current) =>
                previous.usersManagePageState.accountList != current.usersManagePageState.accountList ||
                previous.usersManagePageState.runtimeType != current.usersManagePageState.runtimeType,
            builder: (context, state) {
              if (state.usersManagePageState is! ReadyUsersManagePageState) {
                return Center(child: CircularProgressIndicator());
              }
              if (state.usersManagePageState.accountList.isNotEmpty) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 160,
                  ),
                  itemCount: state.usersManagePageState.accountList.length,
                  itemBuilder: (context, index) {
                    Account account = state.usersManagePageState.accountList[index];
                    return AccountCardWidget(
                      account: account,
                      onEdit: () => PlatformUtils.navigator(context, Constants.registerRoute,<String, dynamic>{
                        'objectParameter' : context.read<WebCubit>().usersManagePageCubit.getEventAccount(account),
                        'typeStatus' : TypeStatus.modify, 'context' : context,},),
                      onLock: () {},
                      onDelete: () => deleteAccount(account, context)
                    );
                  },
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Nessun utente da mostrare", style: title),
                    ],
                  ),
                );
              }
            }
          )
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return gridUsersManage();
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
    super.initState();
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
                        AccountCardWidget(
                          account: state.accountList[index],
                          onEdit: () => PlatformUtils.navigator(context, Constants.registerRoute,<String, dynamic>{
                            'objectParameter' : context.read<UsersManageCubit>().getEventAccount(state.accountList[index]),
                            'typeStatus' : TypeStatus.modify, 'context' : context, 'callback': PlatformUtils.isMobile?context.read<UsersManageCubit>().forceRefresh:null}),
                          onLock: () {},
                          onDelete: () => _deleteAccount(state.accountList[index], context)
                        )
                         : context.read<UsersManageCubit>().canLoadMore?
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

  void _deleteAccount(Account account, BuildContext context){
    ConfirmCancelAlert(context, title: "CANCELLA UTENTE", text: "Confermi la cancellazione del utente?").show().then((value) async {
      if(value.first){
        if (await context.read<UsersManageCubit>().deleteAccount(account))
          await SuccessAlert(context, text: "Utente eliminato!").show();
      }
    });
  }

  @override
  void dispose() {
    context.read<UsersManageCubit>().scrollController.dispose();
    super.dispose();
  }

}

class AccountCardWidget extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onLock;
  final VoidCallback onDelete;

  AccountCardWidget({
    required this.account,
    required this.onEdit,
    required this.onLock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Account.getIconTypology(account.typology).icon, color: yellow, size: 22),
            ),
            SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'Roboto'),
                children: [
                  TextSpan(text: "${account.surname.toUpperCase()} ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: account.name),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              account.email.isNotEmpty ? account.email : 'Nessuna email',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              account.phone.isNotEmpty ? account.phone : 'Nessun telefono',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.edit, onEdit),
                SizedBox(width: 8),
                _buildActionButton(Icons.lock, onLock),
                SizedBox(width: 8),
                _buildActionButton(Icons.delete, onDelete),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: black,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
