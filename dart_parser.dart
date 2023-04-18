import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

class DartParser {
  // TODO: extract class info aswell
  Future<List<ClassInfo>> parseFile({required String filePath}) async {
    final contextCollection = AnalysisContextCollection(
      includedPaths: [filePath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final context = contextCollection.contextFor(filePath);
    final SomeResolvedUnitResult unitResult = await context.currentSession.getResolvedUnit(filePath);

    final visitor = _MethodNamesVisitor(unitResult as ResolvedUnitResult);

    return [ClassInfo(methods: visitor.methods)];
  }
}

class _MethodNamesVisitor extends RecursiveAstVisitor<void> {
  final ResolvedUnitResult unitResult;
  final List<MethodInfo> methods = [];

  _MethodNamesVisitor(this.unitResult) {
    unitResult.unit.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final List<String> comments = [];
    for (AstNode node in node.sortedCommentAndAnnotations) {
      for (SyntacticEntity comment in node.childEntities) {
        comments.add(comment.toString());
      }
    }

    MethodInfo methodInfo = MethodInfo(
      name: node.name.name,
      comments: comments,
      start: unitResult.lineInfo.getLocation(node.body.childEntities.first.offset).lineNumber,
      end: unitResult.lineInfo.getLocation(node.body.childEntities.first.end).lineNumber,
    );
    methods.add(methodInfo);
  }
}

class ClassInfo {
  String name;
  List<MethodInfo> methods;

  ClassInfo({this.name = '', required this.methods});
}

class MethodInfo {
  final String name;
  final List<String> comments;
  final int start;
  final int end;

  MethodInfo({
    required this.name,
    required this.comments,
    required this.start,
    required this.end,
  });
}
