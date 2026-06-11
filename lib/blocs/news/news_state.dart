import 'package:equatable/equatable.dart';
import '../../models/news_model.dart';

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsModel> newsList;
  const NewsLoaded(this.newsList);

  @override
  List<Object?> get props => [newsList];
}

class NewsError extends NewsState {
  final String message;
  const NewsError(this.message);

  @override
  List<Object?> get props => [message];
}

class NewsActionProcessing extends NewsState {}

class NewsActionSuccess extends NewsState {
  final String message;
  const NewsActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
