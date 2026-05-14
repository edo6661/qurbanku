import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/user_saving_model.dart';
import '../../services/savings_service.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final SavingsService _savingsService;
  StreamSubscription<List<UserSavingModel>>?
  _savingsSubscription; // Berubah tipe

  SavingsBloc({required SavingsService savingsService})
    : _savingsService = savingsService,
      super(SavingsInitial()) {
    on<LoadSavingsData>(_onLoadSavingsData);
    on<SavingsUpdated>(_onSavingsUpdated);
    on<SavingsErrorOccurred>(_onSavingsErrorOccurred);
  }

  void _onLoadSavingsData(LoadSavingsData event, Emitter<SavingsState> emit) {
    emit(SavingsLoading());
    _savingsSubscription?.cancel();
    _savingsSubscription = _savingsService
        .getUserSavingsStream(event.userId) // Panggil fungsi yang baru
        .listen(
          (savings) => add(SavingsUpdated(savings)),
          onError: (Object error) =>
              add(SavingsErrorOccurred(error.toString())),
        );
  }

  Future<void> _onSavingsUpdated(
    SavingsUpdated event,
    Emitter<SavingsState> emit,
  ) async {
    final savings = event.savings;
    if (savings.isEmpty) {
      emit(SavingsEmpty());
      return;
    }

    try {
      List<SavingItem> items = [];
      for (var saving in savings) {
        final targetDetail = await _savingsService.getTargetDetail(
          saving.targetId,
        );
        double progressPercentage =
            (saving.currentBalance / targetDetail.targetAmount) * 100;
        if (progressPercentage > 100.0) progressPercentage = 100.0;

        items.add(
          SavingItem(
            userSaving: saving,
            targetDetail: targetDetail,
            progressPercentage: progressPercentage,
          ),
        );
      }
      emit(SavingsLoaded(items));
    } catch (e) {
      emit(SavingsError('Gagal memuat target tabungan:\n${e.toString()}'));
    }
  }

  void _onSavingsErrorOccurred(
    SavingsErrorOccurred event,
    Emitter<SavingsState> emit,
  ) {
    emit(SavingsError(event.error));
  }

  @override
  Future<void> close() {
    _savingsSubscription?.cancel();
    return super.close();
  }
}
