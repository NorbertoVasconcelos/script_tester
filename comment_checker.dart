import 'dart:io';

import 'dart_parser.dart';

void main() async {
  List<ClassInfo> revisionRequired = await _getRequiredRevsion();

  if (revisionRequired.isNotEmpty) {
    print('The following functions require comment revision:');
    for (ClassInfo classInfo in revisionRequired) {
      print('>>> ${classInfo.name}');
      for (MethodInfo method in classInfo.methods) {
        print('${method.name} - ${classInfo.name}:${method.start}');
      }
    }
  } else {
    print('None of the modified functions have comments.');
  }
}

Future<List<ClassInfo>> _getRequiredRevsion() async {
  List<_ChangedLineInfo> changedLines = await _getChangedLines();
  List<ClassInfo> revisionRequired = [];

  // Parse changed files
  final Map<String, Future<List<ClassInfo>>> mapOfChangedClasses = {};
  for (_ChangedLineInfo changedLineInfo in changedLines) {
    mapOfChangedClasses.putIfAbsent(changedLineInfo.fileName, () async {
      var file = File(changedLineInfo.fileName);
      if (!file.existsSync()) {
        throw Exception('File not found: ${changedLineInfo.fileName}');
      }

      DartParser parser = DartParser();
      final List<ClassInfo> classes = await parser.parseFile(filePath: file.absolute.path);

      return classes;
    });
  }

  // Check if revision is required
  for (_ChangedLineInfo changedLineInfo in changedLines) {
    List<ClassInfo> classes = await mapOfChangedClasses[changedLineInfo.fileName] ?? [];

    for (ClassInfo classInfo in classes) {
      final ClassInfo revisionClassInfo = ClassInfo(name: changedLineInfo.fileName, methods: []);
      for (MethodInfo method in classInfo.methods) {
        if (method.start <= changedLineInfo.lineNumber && changedLineInfo.lineNumber <= method.end) {
          // Method has been changed
          if (!method.comments.any((String comment) => changedLineInfo.content.contains(comment))) {
            // Comments haven't been changed
            revisionClassInfo.methods.add(method);
          }
        }
      }

      if (revisionClassInfo.methods.isNotEmpty) {
        revisionRequired.add(revisionClassInfo);
      }
    }
  }

  return revisionRequired;
}

Future<List<_ChangedLineInfo>> _getChangedLines() async {
  var result = await Process.run('git', ['diff', '--unified=0']);
  if (result.exitCode != 0) {
    throw Exception('Failed to get changed lines: ${result.stderr}');
  }
  var lines = (result.stdout as String).split('\n');
  var changedLines = <_ChangedLineInfo>[];
  String? currentFile;
  for (var line in lines) {
    if (line.startsWith('+++ b/')) {
      currentFile = line.substring(6);
    } else if (line.startsWith('@@ ')) {
      var match = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@').firstMatch(line);
      if (match != null) {
        var lineNumber = int.parse(match.group(1)!);
        changedLines.add(_ChangedLineInfo(
          fileName: currentFile ?? '',
          lineNumber: lineNumber,
          content: line,
        ));
      }
    }
  }
  return changedLines;
}

class _ChangedLineInfo {
  final int lineNumber;
  final String fileName;
  final String content;

  _ChangedLineInfo({
    required this.lineNumber,
    required this.fileName,
    required this.content,
  });
}
