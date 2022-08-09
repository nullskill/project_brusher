import 'dart:convert';
import 'dart:io';

import 'package:project_brusher/source_lines_transformer.dart';

/// A brusher for the Flutter `pubspec.yaml` file
class PubspecBrusher {
  PubspecBrusher._();

  static Future<void> brushUpPubspec(File pubspecFile) async {
    final sb = StringBuffer();
    final srcStream = pubspecFile.openRead().transform(SourceLinesTransformer().splitDecodedLines);
    final xtrStream = Stream.fromIterable(LineSplitter().convert(extraLines()));

    for (final stream in [srcStream, xtrStream]) {
      await stream
          .distinct(
            // avoid duplicates of the empty strings
            (p, n) => p.trim() == n.trim(),
          )
          .forEach(
            (s) => sb.writeln(s.trimRight()),
          );
    }

    final writeSink = pubspecFile.openWrite();
    writeSink.write(sb.toString());
    await writeSink.close();
  }

  static String extraLines() {
    return '''
    # assets:
    #   - images/a_dot_burr.jpeg
    #   - images/a_dot_ham.jpeg
    
    # fonts:
    #   - family: Schyler
    #     fonts:
    #       - asset: fonts/Schyler-Regular.ttf
    #       - asset: fonts/Schyler-Italic.ttf
    #         style: italic
    #   - family: Trajan Pro
    #     fonts:
    #       - asset: fonts/TrajanPro.ttf
    #       - asset: fonts/TrajanPro_Bold.ttf
    #         weight: 700''';
  }
}
