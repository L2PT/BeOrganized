import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/details_event/details_event_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_storage_service.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/delete_alert.dart';
import 'package:venturiautospurghi/views/widgets/fab_widget.dart';
import 'package:venturiautospurghi/views/widgets/reject_alert.dart';
import 'package:venturiautospurghi/views/widgets/success_alert.dart';


class DetailsEvent extends StatelessWidget {
  final Event _event;
  DetailsEvent(this._event);

  @override
  Widget build(BuildContext context) {
    var repository = RepositoryProvider.of<CloudFirestoreService>(context);
    Account account = context.read<AuthenticationBloc>().account!;

    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: new BlocProvider(
          create: (_) => DetailsEventCubit(context, repository, account, _event),
          child: _detailsView()
      ),
    );

  }
}


class _detailsView extends StatefulWidget {
  @override
  _detailsViewState createState() => _detailsViewState();
  
  final List<Tab> tabsHeaders = <Tab>[Tab(text: "DETTAGLIO"), Tab(text: "DOCUMENTI"), Tab(text: "NOTE")];
  final DateFormat formatterMonth = new DateFormat('MMM', "it_IT");
  final DateFormat formatterWeek = new DateFormat('E', "it_IT");
  final double sizeIcon = 30; //HANDLE
  final double padding = 15.0;
}

class _detailsViewState extends State<_detailsView> with TickerProviderStateMixin {
  late final TabController _controller;

  _detailsViewState() {
    _controller = new TabController(vsync: this, length: widget.tabsHeaders.length);
  }
  
  @override
  Widget build(BuildContext context) {
    Account account = context.read<AuthenticationBloc>().account!;
    Event event = context.read<DetailsEventCubit>().state.event;

    Widget detailsContent() => ListView(
      physics: BouncingScrollPhysics(),
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.watch_later,
                      size: widget.sizeIcon,
                    ),
                    SizedBox(width: widget.padding,),
                    Text((event.start.day!=event.end.day?DateFormat("(MMM dd) hh:mm",'it_IT'):DateFormat.Hm()).format(event.start) + " - " +
                        (event.start.day!=event.end.day?DateFormat("(MMM dd) hh:mm",'it_IT'):DateFormat.Hm()).format(event.end), style: subtitle_rev)
                  ],
                ),
              ),
              Divider(height: 2, thickness: 2, indent: 35, color: black_light,),
              Container(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child:  Row(
                    children: <Widget>[
                      Icon(
                        Icons.map,
                        size: widget.sizeIcon,
                      ),
                      SizedBox(width: widget.padding,),
                      Container(
                      child:
                         Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                  Text(event.address.isEmpty?'Nessun indirizzo indicato':event.address,
                                    style: subtitle_rev,overflow: TextOverflow.visible,),
                      //Text(event.address, style: subtitle_rev)
                               ],
                             ),
                         ),
                      ),
                    ],
                ),
              ),
              Divider(height: 2, thickness: 2, indent: 35, color: black_light,),
              Container(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.supervised_user_circle,
                      size: widget.sizeIcon,
                    ),
                    SizedBox(width: widget.padding,),
                    Text( event.supervisor!.surname, style: subtitle_rev),
                    SizedBox(width: 5,),
                    Text( event.supervisor!.name, style: subtitle_rev),
                  ],
                ),
              ),
              Divider(height: 2, thickness: 2, indent: 35, color: black_light,),
              Container(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      FontAwesomeIcons.hardHat,
                      size: widget.sizeIcon,
                    ),
                    SizedBox(width: widget.padding,),
                    Text([event.operator, ...event.suboperators].map((operator) => "${operator?.name} ${operator?.surname}").reduce((value, element) => value+"; "+element), style: subtitle_rev)
                  ],
                ),
              ),
              Divider(height: 2, thickness: 2, indent: 35, color: black_light,),
              account.supervisor ?
              Column(
                  children: <Widget>[Container(
                      padding: event.isRefused()?EdgeInsets.only(top: 15.0):EdgeInsets.symmetric(vertical: 15.0),
                      child: Row(
                          children: <Widget>[
                            Icon(
                              EventStatus.getIcon(event.status),
                              size: widget.sizeIcon,
                            ),
                            SizedBox(width: widget.padding,),
                            Text(EventStatus.getText(event.status), style: subtitle_rev),
                          ]
                      )),
                      event.isRefused()?
                      Container(
                        padding: EdgeInsets.only( bottom: 15.0),
                        child: Row(
                          children: [
                            SizedBox(width: widget.padding+widget.sizeIcon,),
                            Expanded(
                              child: Text(event.motivazione == null?'Nessuna motivazione indicata':event.motivazione,
                                style: label_rev, overflow: TextOverflow.visible,),
                            ),
                          ],
                        ),
                      ): Container(),
                      Divider(height: 2, thickness: 2, indent: 35, color: black_light,)]
              ): Container(),
              Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.assignment, size: widget.sizeIcon,),
                    SizedBox(width: widget.padding,),
                    Container(
                      child: Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(string.isNullOrEmpty(event.description)?'Nessuna nota indicata':event.description.substring(0,min<int>(event.description.length,80)),
                              style: subtitle_rev,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 5,
                            ),
                            SizedBox(height: 15),
                            event.description.isNotEmpty?
                            GestureDetector(
                              child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: HexColor(event.color),
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                                  ),
                                  child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: 3, bottom: 3, left: 20, right: 20),
                                        child: Text("LEGGI",
                                          style: subtitle_rev.copyWith(color: white),
                                        ),
                                      ))),
                              onTap: () => _controller.animateTo(2),
                            ):Container()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );

    Widget detailsDocument() => Container(
        margin: EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
        child: event.documents.length>0?ListView.separated(
            itemCount: event.documents.length,
            itemBuilder: (BuildContext context, int index) {
              final String fileName = event.documents[index];
              return new Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  child: Row(children: <Widget>[
                    Icon(Icons.insert_drive_file, size: widget.sizeIcon, color: black),
                    SizedBox(
                      width: widget.padding,
                    ),
                    Expanded(child: Container(
                        child: Text(fileName,
                          style: subtitle.copyWith(color: black, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.visible,
                        )
                    ),),
                    IconButton(
                      icon:Icon(Icons.file_download, size: widget.sizeIcon, color: black),
                      onPressed: () async {
                        var url = await FirebaseStorageService.downloadURL(event.id+"/"+fileName);
                        if( await PlatformUtils.download(url, fileName))
                          SuccessAlert(context, text: "Documento scaricato!", icon: Icons.download_done_rounded).show();
                      },
                    ),
                  ])
              );
            },
            separatorBuilder: (BuildContext context, int index){return SizedBox(height: 10.0,);}
        ):Container(
          padding: EdgeInsets.all(10.0),
          child:
              Text("Nessun documento per questo interveto",
                style: subtitle.copyWith(
                    color: white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
              )
        ),
    );

    Widget detailsNote() => Container(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
        child: Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.assignment,
                    size: widget.sizeIcon,
                  ),
                  SizedBox(
                    width: widget.padding,
                  ),
                  new Expanded(
                      flex: 1,
                      child: new SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: new Text(event.description.isEmpty?'Nessuna nota indicata':event.description, style: subtitle_rev),
                      ))
                ],
              ),
            ),
          ],
        ));

    List<Widget> _tabsContents = [detailsContent(),detailsDocument(),detailsNote()];

    Widget tabView = new BlocBuilder<DetailsEventCubit, DetailsEventState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          account = context.read<AuthenticationBloc>().account!;
          event = context.read<DetailsEventCubit>().state.event;
          return  TabBarView(
            controller: _controller,
            children: _tabsContents.map((Widget tab) {
              return tab;
            }).toList(),
          );
        }
    );

    return new Scaffold(
        appBar: AppBar(
            title: Text('INTERVENTO'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: white),
              onPressed: () => PlatformUtils.backNavigator(context),
        )),
        floatingActionButton: Fab(),
        body: Material(
            elevation: 12.0,
            child: Stack(children: <Widget>[
              Container(
                  child: Column(children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: Row(children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: Container(color: black),
                        ),
                        Expanded(
                          flex: 5,
                          child: Container(color: HexColor(event.color)),
                        )
                      ]),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(color: grey),
                    )
                  ])),
              Container(
                  child: Column(children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                          color: HexColor(event.color),
                          borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(30.0))),
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 20),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 30,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: black,
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(25.0))),
                              width: 55,
                              height: 100,
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Center(
                                    child: Text(widget.formatterMonth.format(event.start).toUpperCase(),
                                        style: title_rev.copyWith(fontSize: 15)),
                                  ),
                                  Center(
                                    child: Text("${event.start.day}",
                                        style: title_rev.copyWith(fontSize: 15)),
                                  ),
                                  Center(
                                    child: Text(widget.formatterWeek.format(event.start),
                                        style: title_rev.copyWith(fontSize: 15)),
                                  )
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(event.title.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                    style: title),
                                Text(event.category.toUpperCase(),
                                    style: subtitle.copyWith(color: black)),
                              ],
                             )
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: black,
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: whitebackground,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30.0))),
                                    child: new TabBar(
                                      isScrollable: true,
                                      unselectedLabelColor: black,
                                      labelStyle: title.copyWith(fontSize: 16),
                                      labelColor: black,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: new BubbleTabIndicator(
                                        indicatorHeight: 40.0,
                                        indicatorColor:
                                        HexColor(event.color),
                                        tabBarIndicatorSize:
                                        TabBarIndicatorSize.tab,
                                      ),
                                      tabs: widget.tabsHeaders,
                                      controller: _controller,
                                    ),
                                  ),
                                  Expanded(
                                      child: tabView
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 150,
                            decoration: BoxDecoration(
                                color: HexColor(event.color),
                                borderRadius:
                                BorderRadius.all(Radius.circular(15.0))),
                          )
                        ],
                      ),
                    ),PlatformUtils.eventButtonsVisible(context, event, account)?
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            child: new Text('RIFIUTA', style: button_card),
                            onPressed: () async {
                              RejectAlert(context).show().then((justification)=>!string.isNullOrEmpty(justification)? context.read<DetailsEventCubit>().refuseEventAndNotify(justification):null);
                            }
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(
                            child: new Text('ACCETTA', style: button_card),
                            onPressed: context.read<DetailsEventCubit>().acceptEventAndNotify,
                          ),
                          SizedBox(width: 30,),
                        ],
                      ),
                    ): event.isAccepted() && DateTime.now().isAfter(event.start) && event.operator!.id == account.id?
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            child: new Text('TERMINA', style: button_card),
                            onPressed: () async {
                              if(await ConfirmCancelAlert(context, title: "TERMINA INCARICO", text: "Confermi la terminazione dell'incarico?").show())
                                context.read<DetailsEventCubit>().endEventAndNotify();
                            },
                          ),
                        ],
                      ),
                    ):event.isEnded()?
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                                  color: HexColor(event.color),
                                  boxShadow: <BoxShadow> [BoxShadow(color: Colors.black45,
                                    offset: Offset(1.0, 2.5),
                                    blurRadius: 5.0,)]

                              ),
                              child: Text('INCARICO TERMINATO', style: button_card),
                              padding: EdgeInsets.all(10),

                            ),
                          )
                          ,
                        ],
                      ),
                    ):
                    Container(height: 30,)
                    /*child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 30,
                    ),
                    Icon(
                      Icons.notifications,
                      size: 40,
                    ),
                    Text("Avvisami (15m)", style: subtitle_rev),
                    SizedBox(width: 30),
                    Switch(value: true, activeColor: c, onChanged: (v) {})
                  ],
                ),*/])),
            ])));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
}
