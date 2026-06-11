import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/news_service.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsService _newsService;
  StreamSubscription? _newsSubscription;

  NewsBloc({required NewsService newsService})
    : _newsService = newsService,
      super(NewsInitial()) {
    on<LoadNews>(_onLoadNews);
    on<NewsUpdated>(_onNewsUpdated);
    on<AddNewsRequested>(_onAddNewsRequested);
    on<UpdateNewsRequested>(_onUpdateNewsRequested);
    on<DeleteNewsRequested>(_onDeleteNewsRequested);
  }

  void _onLoadNews(LoadNews event, Emitter<NewsState> emit) {
    emit(NewsLoading());
    _newsSubscription?.cancel();
    _newsSubscription = _newsService.getNewsStream().listen(
      (newsList) {
        add(NewsUpdated(newsList));
      },
      onError: (error) {
        emit(NewsError('Gagal memuat berita: ${error.toString()}'));
      },
    );
  }

  void _onNewsUpdated(NewsUpdated event, Emitter<NewsState> emit) {
    emit(NewsLoaded(event.newsList));
  }

  Future<void> _onAddNewsRequested(
    AddNewsRequested event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsActionProcessing());
    try {
      await _newsService.createNews(
        title: event.title,
        description: event.description,
        imageFile: event.imageFile,
      );
      emit(const NewsActionSuccess('Berita berhasil ditambahkan!'));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> _onUpdateNewsRequested(
    UpdateNewsRequested event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsActionProcessing());
    try {
      await _newsService.updateNews(
        id: event.id,
        title: event.title,
        description: event.description,
        currentImageUrl: event.currentImageUrl,
        newImageFile: event.newImageFile,
      );
      emit(const NewsActionSuccess('Berita berhasil diperbarui!'));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> _onDeleteNewsRequested(
    DeleteNewsRequested event,
    Emitter<NewsState> emit,
  ) async {
    try {
      await _newsService.deleteNews(event.id);
      // Tidak perlu emit action success agar list tidak berkedip,
      // Stream _newsSubscription akan otomatis me-refresh data.
    } catch (e) {
      emit(NewsError('Gagal menghapus berita: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _newsSubscription?.cancel();
    return super.close();
  }
}
