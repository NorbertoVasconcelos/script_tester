import 'dart:io';

void main() async {
  var changedLines = await getChangedLines();
  var functionsWithComments = <String>{};

  for (var line in changedLines) {
    var parts = line.split(':');
    var filename = parts[0];
    var lineNumber = int.parse(parts[1]);

    var file = File(filename);
    if (!file.existsSync()) {
      throw Exception('File not found: $filename');
    }

    var contents = await file.readAsLines();
    var functionLineNumbers = getFunctionLineNumbers(contents);

    for (var functionLines in functionLineNumbers) {
      if (functionLines.start <= lineNumber && lineNumber <= functionLines.end) {
        if (hasComment(contents.sublist(functionLines.start - 2, functionLines.end))) {
          functionsWithComments.add('${file.path}:${functionLines.start}');
        }
      }
    }
  }

  if (functionsWithComments.isNotEmpty) {
    print('The following functions have comments:');
    for (var functionLocation in functionsWithComments) {
      print(' - $functionLocation');
    }
  } else {
    print('None of the modified functions have comments.');
  }
}

Future<List<String>> getChangedLines() async {
  var result = await Process.run('git', ['diff', '--unified=0']);
  if (result.exitCode != 0) {
    throw Exception('Failed to get changed lines: ${result.stderr}');
  }
  var lines = (result.stdout as String).split('\n');
  var changedLines = <String>[];
  String? currentFile;
  for (var line in lines) {
    if (line.startsWith('+++ b/')) {
      currentFile = line.substring(6);
    } else if (line.startsWith('@@ ')) {
      var match = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@').firstMatch(line);
      if (match != null) {
        var lineNumber = int.parse(match.group(1)!);
        changedLines.add('$currentFile:$lineNumber');
      }
    }
  }
  return changedLines;
}

List<LineRange> getFunctionLineNumbers(List<String> lines) {
  var functionLineNumbers = <LineRange>[];
  var currentFunction = _Function(null, -1, -1);

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();

    if (line.startsWith('///') && currentFunction.start != -1 && currentFunction.end != -1) {
      functionLineNumbers.add(LineRange(currentFunction.start, currentFunction.end));
      currentFunction = _Function(null, -1, -1);
    }

    if (line.isEmpty) {
      continue;
    }

    if (line.endsWith('{')) {
      currentFunction = _Function(line, i + 1, -1);
    } else if (line.endsWith('}') && currentFunction.start != -1) {
      currentFunction.end = i + 1;
      functionLineNumbers.add(LineRange(currentFunction.start, currentFunction.end));
      currentFunction = _Function(null, -1, -1);
    }
  }

  return functionLineNumbers;
}

/// Checks if a line has a comment
bool hasComment(List<String> lines) {
  return lines.any((line) => line.trim().startsWith('///'));
}

class LineRange {
  final int start;
  final int end;

  LineRange(this.start, this.end);
}

class _Function {
  final String? declaration;
  int start;
  int end;

  _Function(this.declaration, this.start, this.end);
}
