import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:project_brusher/pubspec_brusher.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  late final FileSystemEntity pubspecEntity;

  final dir = Directory(args[0]);
  // final dir = Directory('/Users/ilya/dev/projects/temp');
  final List<FileSystemEntity> fsEntities = await dir.list().where((e) => FileSystemEntity.isFileSync(e.path)).toList();

  try {
    pubspecEntity = fsEntities.singleWhere((element) => element.path.endsWith('pubspec.yaml'));
  } catch (error) {
    if (error is StateError && error.message == 'Too many elements') {
      print('Too many `pubspec.yaml` files in the project!');
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
    PubspecBrusher.brushUpPubspec(pubspecFile);
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
