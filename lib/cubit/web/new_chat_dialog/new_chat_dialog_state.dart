import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/message/contact_whatsapp.dart';

abstract class NewChatDialogState extends Equatable {
  const NewChatDialogState();

  @override
  List<Object?> get props => [];
}

class NewChatDialogLoading extends NewChatDialogState {}

class NewChatDialogDisconnected extends NewChatDialogState {}

class NewChatDialogData extends NewChatDialogState {
  final int currentStep;
  final List<dynamic> searchResults;
  final ContactWhatsapp? selectedContact;
  final String messageText;
  final bool hasReachedMax;
  final String currentQuery;
  final bool isLoadingMore;

  const NewChatDialogData({
    this.currentStep = 0,
    this.searchResults = const [],
    this.selectedContact,
    this.messageText = '',
    this.hasReachedMax = false,
    this.currentQuery = '',
    this.isLoadingMore = false,
  });

  NewChatDialogData copyWith({
    int? currentStep,
    List<dynamic>? searchResults,
    ContactWhatsapp? selectedContact,
    String? messageText,
    bool? hasReachedMax,
    String? currentQuery,
    bool? isLoadingMore,
  }) {
    return NewChatDialogData(
      currentStep: currentStep ?? this.currentStep,
      searchResults: searchResults ?? this.searchResults,
      selectedContact: selectedContact ?? this.selectedContact,
      messageText: messageText ?? this.messageText,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentQuery: currentQuery ?? this.currentQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [currentStep, searchResults, selectedContact, messageText, hasReachedMax, currentQuery, isLoadingMore];
}
