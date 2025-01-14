part of 'web_bloc.dart';

@immutable
abstract class WebState extends Equatable {
  final String route;
  final dynamic content;

  WebState(this.route, this.content);

  @override
  List<Object> get props => [route,content??""];
}

class Ready extends WebState {

  Ready(String route, [content]) : super(route, content);

}

class OverViewReady extends WebState {
  Function? callback;
  double posLeftOverView = 0;
  double posTopOverView = 0;

  OverViewReady(String route, content, this.posLeftOverView, this.posTopOverView, [ this.callback ]) : super(route, content);

  @override
  List<Object> get props => [route,content, posLeftOverView, posLeftOverView];

  OverViewReady.update(String route, content,this.posLeftOverView, this.posTopOverView): super(route, content);

  OverViewReady assign({
    String? route, content,
    double? posLeftOverView,
    double? posTopOverView,
  }) => OverViewReady.update(
    route??this.route,
    content??this.content,
    posLeftOverView?? this.posLeftOverView,
    posTopOverView?? this.posTopOverView,
  );


}

class CloseOverView extends WebState {
  final dynamic arg;
  bool result;
  Function? callback;

  CloseOverView(this.arg,String route, this.result, [this.callback, content]) : super(route, content);

  @override
  List<Object> get props => [result, arg];

}

class NotReady extends WebState {
  NotReady() : super("", null);
}