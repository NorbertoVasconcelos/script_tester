import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

void main() {
  final projectDir = Directory(
      '/Users/norbertovasconcelos/Documents/Practice/script_tester'); // change this to the root directory of your project
  final files = _getDartFiles(projectDir);
  final changedFunctions = _findChangedFunctions(files);
  _checkComments(changedFunctions ?? {});
}

List<File> _getDartFiles(Directory directory) {
  return directory.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).toList();
}

Map<String, List<int>>? _findChangedFunctions(List<File> files) {
  final results = <String, List<int>>{};
  // use your favorite tool to determine which files have been changed
  // for example, you can use Git to get the list of changed files:
  final changedFiles = Process.runSync('git', ['diff', '--name-only', 'HEAD', '--', '*.dart']);
  final lines = (changedFiles.stdout as String).split('\n');
  for (final line in lines) {
    final File? file = files.firstWhereOrNull((File f) => f.path == line);
    if (file == null) {
      continue;
    }
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('{' /* or any other criteria to identify a function */)) {
        // you can use any unique identifier for a function instead of the opening curly brace
        final name = _getFunctionName(lines, i);
        results.putIfAbsent(file.path, () => []).add(i);
      }
    }
  }
  return results;
}

String? _getFunctionName(List<String> lines, int index) {
  // extract the function name from the function signature
  final line = lines[index].trim();
  final parts = line.split(' ');
  if (parts.length >= 2) {
    final name = parts[1];
    return name.split('(')[0];
  }
  return null;
}

void _checkComments(Map<String, List<int>> changedFunctions) {
  for (final entry in changedFunctions.entries) {
    final file = File(entry.key);
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    for (final index in entry.value) {
      final name = _getFunctionName(lines, index);
      final commentLine = _findCommentLine(lines, index);
      if (commentLine == null) {
        print('Function "$name" in file "${entry.key}" does not have a comment');
      }
    }
  }
}

int? _findCommentLine(List<String> lines, int index) {
  // find the line before the function signature that starts with '///'
  for (var i = index - 1; i >= 0; i--) {
    final line = lines[i].trim();
    if (line.startsWith('///')) {
      return i;
    } else if (line.isNotEmpty) {
      // if the line is not empty and does not start with '///', then it's not a comment
      return null;
    }
  }
  return null;
}
