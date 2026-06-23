import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';

/// The narration lifecycle, mirroring the state flow from the brief:
/// idle → loading → speaking → completed, with a parallel [error] state
/// reachable from loading or speaking.
enum NarrationStatus { idle, loading, speaking, completed, error }

class TtsState {
  final NarrationStatus status;
  final String? errorMessage;

  const TtsState({
    this.status = NarrationStatus.idle,
    this.errorMessage,
  });

  bool get isBusy =>
      status == NarrationStatus.loading || status == NarrationStatus.speaking;

  TtsState copyWith({
    NarrationStatus? status,
    String? errorMessage,
  }) {
    return TtsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TtsState &&
      other.status == status &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, errorMessage);
}

/// Owns the single [TtsService] instance and disposes it when the provider
/// is torn down, preventing leaked platform channels.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Drives narration state. Screens/widgets call [narrate] and react to the
/// resulting [TtsState] — they never talk to [TtsService] directly.
class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier(this._service) : super(const TtsState());

  final TtsService _service;

  Future<void> narrate(String text) async {
    // Guard against double-taps while narration is already in flight.
    if (state.isBusy) return;

    state = state.copyWith(status: NarrationStatus.loading);

    await _service.speak(
      text: text,
      onStart: () {
        state = state.copyWith(status: NarrationStatus.speaking);
      },
      onComplete: () {
        state = state.copyWith(status: NarrationStatus.completed);
      },
      onError: (message) {
        state = TtsState(
          status: NarrationStatus.error,
          errorMessage: message,
        );
      },
    );
  }

  Future<void> stop() async {
    await _service.stop();
    state = state.copyWith(status: NarrationStatus.idle);
  }

  void reset() {
    state = const TtsState();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  final service = ref.watch(ttsServiceProvider);
  return TtsNotifier(service);
});
