import 'package:flutter_tts/flutter_tts.dart';

/// Thin, testable wrapper around [FlutterTts].
///
/// Keeping the raw plugin behind this service means:
///   - `TtsProvider` (Riverpod) never touches the plugin API directly.
///   - We have one place to handle platform quirks (engine init failures,
///     missing voices, etc.) and one place to dispose resources safely.
class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _isInitialized = false;

  /// Configures the TTS engine. Throws a [TtsException] with a
  /// child-friendly message if initialization fails (e.g. no TTS engine
  /// installed on the device, which does happen on some budget Android
  /// builds).
  Future<void> initialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42); // Slower, clearer pace for children.
      await _tts.setPitch(1.05); // Slightly bright/friendly pitch.
      await _tts.setVolume(1.0);

      // awaitSpeakCompletion makes `speak()` resolve only once narration
      // truly finishes, which is what lets us await it cleanly below.
      // On a handful of older Android builds this call has been reported
      // to throw rather than fail silently, so we isolate it and treat a
      // failure here as non-fatal — speak() still works, it just resolves
      // immediately rather than waiting, and our handler-based callbacks
      // (onComplete/onError) remain the real source of truth either way.
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {
        // Swallow: completion/error handlers below still drive state.
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw TtsException(
        "Oops! Our storyteller's voice isn't ready yet. Let's try again!",
        cause: e,
      );
    }
  }

  /// Speaks [text], invoking [onStart] right before speech begins,
  /// [onComplete] when it finishes naturally, and [onError] if anything
  /// goes wrong mid-speech (engine crash, interruption, etc.).
  ///
  /// Note on flutter_tts's API shape: with `awaitSpeakCompletion(true)`
  /// (set in [initialize]), `_tts.speak()` itself doesn't resolve until
  /// the engine is done — but `setCompletionHandler` *also* fires at that
  /// same moment. To avoid invoking [onComplete] twice, completion is
  /// reported exclusively from the handlers below; the awaited `speak()`
  /// call is only used to detect a same-call-stack failure (e.g. no TTS
  /// engine available), not to drive success.
  Future<void> speak({
    required String text,
    required void Function() onStart,
    required void Function() onComplete,
    required void Function(String message) onError,
  }) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        onError(
          e is TtsException ? e.message : "Oops! Let's try that again.",
        );
        return;
      }
    }

    var settled = false;
    void completeOnce() {
      if (!settled) {
        settled = true;
        onComplete();
      }
    }

    void errorOnce(String message) {
      if (!settled) {
        settled = true;
        onError(message);
      }
    }

    _tts.setStartHandler(onStart);
    _tts.setCompletionHandler(completeOnce);
    _tts.setCancelHandler(completeOnce);
    _tts.setErrorHandler((message) {
      errorOnce("Oops! Let's try that again.");
    });

    try {
      final result = await _tts.speak(text);
      // A non-1 result signals immediate failure (e.g. engine rejected
      // the request) on platforms that report it synchronously.
      if (result != 1) {
        errorOnce("Oops! Let's try that again.");
      }
    } catch (e) {
      errorOnce("Oops! Let's try that again.");
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Stopping is best-effort; nothing the user needs to see if it fails.
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}

class TtsException implements Exception {
  final String message;
  final Object? cause;

  const TtsException(this.message, {this.cause});

  @override
  String toString() => 'TtsException: $message';
}
