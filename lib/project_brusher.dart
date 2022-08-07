import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:project_brusher/source_lines_transformer.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  late final FileSystemEntity pubspecEntity;

  // final dir = Directory(args[0]);
  final dir = Directory('/Users/ilya/dev/projects/temp');
  final List<FileSystemEntity> fsEntities = await dir.list().where((e) => FileSystemEntity.isFileSync(e.path)).toList();
  // for (final fsEntity in fsEntities) {
  //   print(fsEntity);
  // }

  try {
    pubspecEntity = fsEntities.singleWhere((element) => element.path.endsWith('pubspec.yaml'));
  } catch (error) {
    if (error is StateError && error.message == 'Too many elements') {
      print('Too many `pubspec.yaml`files in the project!');
    } else {
      print('This is not a Dart/Flutter project!');
    }
    return;
  }

  final pubspecFile = File(pubspecEntity.path);
  if (await pubspecFile.length() == 0) {
    print('`pubspec.yaml` is empty!');
    return;
  }

  final pubspecString = await pubspecFile.openRead().transform(utf8.decoder).first;
  final pubspec = loadYaml(pubspecString, sourceUrl: pubspecFile.uri);
  if (pubspec is! YamlMap) {
    print('Unable to read `pubspec.yaml`');
    return;
  }

  bool isFlutterProj = isFlutterProject(pubspec);

  if (isFlutterProj) {
    brushUpPubspec(pubspecFile);
  }
}

bool isFlutterProject(YamlMap yaml) {
  if (yaml.keys.contains('dependencies')) {
    final depsNode = yaml['dependencies'];
    if (depsNode.keys.contains('flutter')) {
      final flutterNode = depsNode['flutter'];
      if (flutterNode.keys.contains('sdk')) {
        final flutterSdkNode = flutterNode['sdk'];
        if (flutterSdkNode == 'flutter') {
          return true;
        }
      }
    }
  }

  return false;
}

Future<void> brushUpPubspec(File pubspecFile) async {
  final sb = StringBuffer();
  final srcStream = pubspecFile.openRead().transform(SourceLinesTransformer().splitDecodedLines);
  final xtrStream = Stream.fromIterable(LineSplitter().convert(pubspecExtraLines()));

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

String pubspecExtraLines() {
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
