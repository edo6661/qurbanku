import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/news_model.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNews extends NewsEvent {}

class NewsUpdated extends NewsEvent {
  final List<NewsModel> newsList;
  const NewsUpdated(this.newsList);

  @override
  List<Object?> get props => [newsList];
}

class AddNewsRequested extends NewsEvent {
  final String title;
  final String description;
  final File imageFile;

  const AddNewsRequested({
    required this.title,
    required this.description,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [title, description, imageFile];
}

class UpdateNewsRequested extends NewsEvent {
  final String id;
  final String title;
  final String description;
  final String currentImageUrl;
  final File? newImageFile;

  const UpdateNewsRequested({
    required this.id,
    required this.title,
    required this.description,
    required this.currentImageUrl,
    this.newImageFile,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    currentImageUrl,
    newImageFile,
  ];
}

class DeleteNewsRequested extends NewsEvent {
  final String id;
  const DeleteNewsRequested(this.id);

  @override
  List<Object?> get props => [id];
}
