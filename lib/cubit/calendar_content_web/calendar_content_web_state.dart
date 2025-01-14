part of 'calendar_content_web_cubit.dart';

abstract class CalendarContentWebState extends Equatable {
  bool showHoverContainer = false;
  double posTop = 110;
  double posLeft = 0;
  Event eventHover = Event.empty();
  double widthOpeCalendar = 150;
  Account user;

  CalendarContentWebState(this.user);

  @override
  List<Object> get props => [this.showHoverContainer, this.posLeft, this.posTop, this.eventHover, this.widthOpeCalendar, this.user];

  CalendarContentWebState.update(this.eventHover, this.posLeft, this.posTop, this.showHoverContainer,
      this.widthOpeCalendar, this.user,);

  CalendarContentWebReady assign({
    bool? showHoverContainer,
    double? posTop,
    double? posLeft,
    Event? eventHover,
    double? widthOpeCalendar,
    Account? user,
  }) => CalendarContentWebReady.update(
    showHoverContainer?? this.showHoverContainer,
    posLeft??this.posLeft,
    posTop??this.posTop,
    eventHover??this.eventHover,
    widthOpeCalendar??this.widthOpeCalendar,
    user??this.user,
  );

}
class  CalendarContentWebLoading extends  CalendarContentWebState{
  CalendarContentWebLoading( Account user):super(user);
}

class CalendarContentWebReady extends CalendarContentWebState {

  CalendarContentWebReady( Account user): super(user);

  CalendarContentWebReady.update(
      bool showHoverContainer,
      double posLeft,
      double posTop,
      Event eventHover,
      double widthOpeCalendar,
      Account user,
      )
      : super.update(eventHover, posLeft, posTop, showHoverContainer, widthOpeCalendar, user);


}