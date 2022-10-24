import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:project_brusher/pubspec_brusher.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  late final FileSystemEntity pubspecEntity;

  if (args.isEmpty) {
    throw FormatException('No project path provided!');
  }

  // final path = '/Users/ilya/dev/projects/ttt';
  final path = args.first;

  final dir = Directory.fromUri(getProjectUri(path));
  final List<FileSystemEntity> fsEntities = await dir.list().where((e) => FileSystemEntity.isFileSync(e.path)).toList();

  try {
    pubspecEntity = fsEntities.singleWhere((element) => element.path.endsWith('pubspec.yaml'));
  } catch (error) {
    if (error is StateError && error.message == 'Too many elements') {
      throw Exception('Too many `pubspec.yaml` files in the project!');
    } else {
      throw Exception('This is not a Dart/Flutter project!');
    }
  }

  final pubspecFile = File(pubspecEntity.path);
  if (await pubspecFile.length() == 0) {
    throw Exception('`pubspec.yaml` is empty!');
  }

  final pubspecString = await pubspecFile.openRead().transform(utf8.decoder).first;
  final pubspec = loadYaml(pubspecString, sourceUrl: pubspecFile.uri);
  if (pubspec is! YamlMap) {
    throw Exception('Unable to read `pubspec.yaml`');
  }

  bool isFlutterProj = isFlutterProject(pubspec);

  if (isFlutterProj) {
    PubspecBrusher.brushUpPubspec(pubspecFile);
  }
}

Uri getProjectUri(String path) {
  return Uri.parse(path);
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
