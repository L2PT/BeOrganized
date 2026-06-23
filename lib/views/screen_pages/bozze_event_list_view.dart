import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/screens/filter_event_list_view.dart';

class BozzeEventList extends StatefulWidget {

  @override
  _BozzeEventListState createState() => _BozzeEventListState();
}

class _BozzeEventListState extends State<BozzeEventList> {

  @override
  void initState() {
    super.initState();
    if(!PlatformUtils.isMobile) {
      context.read<WebCubit>().initCubit(Constants.bozzeEventListRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterEventList(isBozze: true,);
  }

}
