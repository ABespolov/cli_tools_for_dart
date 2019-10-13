import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'library.dart';
import 'line.dart';
import 'move_result.dart';

class MoveCommand extends Command<void> {
  // This is the lib directory
  Directory libRoot;
  @override
  String get description =>
      "Moves a dart library and updates all import statements to reflect its now location.";

  @override
  String get name => "move";

  void run() async {
    // remove after testing complete
    // Directory.current = "./test/data/";

    libRoot = Directory(p.join(Directory.current.path, 'lib'));

    Line.init();

    if (argResults.rest.length != 2) {
      fullusage();
    }
    if (!await File("pubspec.yaml").exists()) {
      fullusage(
          error: "The pubspec.yaml is missing from: ${Directory.current}");
    }

    // check we are in the root.
    if (!await libRoot.exists()) {
      fullusage(error: "You must run a move from the root of the package.");
    }

    String from = argResults.rest[0];
    String to = argResults.rest[1];

    File fromPath = await validFrom(from);
    File toPath = await validTo(to);

    process(fromPath, toPath);
  }

  void process(File fromPath, File toPath) async {
    Stream<FileSystemEntity> files = Directory.current.list(recursive: true);

    List<FileSystemEntity> dartFiles =
        await files.where((file) => file.path.endsWith(".dart")).toList();

    List<MoveResult> updatedFiles = List();
    int scanned = 0;
    int updated = 0;
    for (var library in dartFiles) {
      scanned++;

      Library processing = Library(File(library.path), libRoot);
      MoveResult result =
          await processing.updateImportStatements(fromPath, toPath);

      if (result.changeCount != 0) {
        updated++;
        updatedFiles.add(result);

        print("Updated : ${library.path} changed ${result.changeCount} lines");
      }
    }

    await overwrite(updatedFiles);

    await fromPath.exists();

    await fromPath.rename(toPath.path);
    print("Finished: scanned $scanned updated $updated");
  }

  void fullusage({String error}) {
    if (error != null) {
      print("Error: $error");
      print("");
    }

    print("Usage: ");
    print("Run the move from the root of the package");
    print("move <from path> <to path>");
    print("e.g. move apps/string.dart  util/string.dart");
    print(argParser.usage);

    exit(-1);
  }

  Future<File> validFrom(String from) async {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as the see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.
    File actualPath = File(p.canonicalize(p.join("lib", from)));

    if (!await actualPath.exists()) {
      fullusage(
          error:
              "The <fromPath> is not a valid filepath: '${actualPath.path}'");
    }
    return actualPath;
  }

  Future<File> validTo(String to) async {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as the see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.
    File actualPath = File(p.canonicalize(p.join("lib", to)));
    if (!await actualPath.parent.exists()) {
      fullusage(
          error: "The <toPath> directory does not exist: ${actualPath.parent}");
    }
    return actualPath;
  }

  void overwrite(List<MoveResult> updatedFiles) async {
    for (MoveResult result in updatedFiles) {
      await result.library.overwrite(result.tmpFile);
    }
  }
}
