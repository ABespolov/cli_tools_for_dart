import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';
import 'util/yaml_me.dart';

class ACommand extends Command<void> {
  Directory lib;

  void run() async {
    lib = Directory(p.join(Directory.current.path, 'lib'));
    p.relative("hi");
    YamlMe("pubspec.yaml");
  }

  @override
  String get description => "Acommand";

  @override
  String get name => "ACommand";
}
