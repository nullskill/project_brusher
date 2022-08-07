import 'dart:async';
import 'dart:convert';

class SourceLinesTransformer extends StreamTransformerBase<String, String> {
  const SourceLinesTransformer();

  StreamTransformer<List<int>, String> get splitDecodedLines => StreamTransformer<List<int>, String>.fromBind(
        (stream) => stream.transform(utf8.decoder).transform(LineSplitter()).transform(this),
      );

  @override
  Stream<String> bind(Stream<String> stream) {
    final controller =
        stream.isBroadcast ? StreamController<String>.broadcast(sync: true) : StreamController<String>(sync: true);
    return (controller..onListen = () => _onListen(stream, controller)).stream;
  }

  void _onListen(Stream<String> stream, StreamController<String> controller) {
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    controller.onCancel = subscription.cancel;
    if (!stream.isBroadcast) {
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    }

    String? previousLine;

    subscription
      ..onData(
        (String data) {
          if (!data.trimLeft().startsWith('#')) {
            if (data.isEmpty && (previousLine?.isEmpty ?? true)) return;
            sink.add('$data\n');
            // print(data);
            previousLine = data;
          }
        },
      )
      ..onError((Object error, StackTrace stackTrace) => sink.addError(error, stackTrace))
      ..onDone(() => sink.close());
  }
}
