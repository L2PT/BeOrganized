import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/widgets/fab_widget.dart';

part 'fab_state.dart';

class FabCubit extends Cubit<FabState> {
  final BuildContext _context;
  final String _route;
  final Account _account;

  FabCubit(this._context, this._databaseRepository, this._account, this._route) :
        super(FabState()) {
    if(_account.supervisor) {
      if(_route == Constants.detailsEventViewRoute) content = Fab_details_super(_context);
      else if(_route == Constants.dailyCalendarRoute) content = Fab_daily_super();
    } else {
      if(_route == Constants.detailsEventViewRoute) content = Fab_details_oper(_context);
    }
  }

  final CloudFirestoreService _databaseRepository;
  Widget content = SizedBox();

  void callSupervisor(String phone) async {
    Uri phoneUri = Uri.parse("tel:"+phone);
    if(await canLaunchUrl(phoneUri)){
      launchUrl(phoneUri);
    }
  }

  void callOffice() async {
    String officeNumber = "tel:"+(await _databaseRepository.getPhoneNumbers())["ufficio"];
    if(await canLaunch(officeNumber)){
      launch(officeNumber);
    }
  }

}
