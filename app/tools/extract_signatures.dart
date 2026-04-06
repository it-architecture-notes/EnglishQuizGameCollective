import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

void main() async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory('lib').absolute.path],
  );

  final buffer = StringBuffer();

  for (final context in collection.contexts) {
    for (final path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart')) continue;

      final result = await context.currentSession.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) continue;

      final relativePath = path.replaceFirst(Directory.current.path, '');
      buffer.writeln('\n## $relativePath');

      final library = result.libraryElement;

      for (final cls in library.topLevelElements.whereType<ClassElement>()) {
        buffer.writeln(
          '\nclass ${cls.name}'
          '${cls.supertype != null ? " extends ${cls.supertype!.element.name}" : ""}',
        );
        for (final method in cls.methods) {
          buffer.writeln('  ${_methodSig(method)}');
        }
        for (final accessor in cls.accessors) {
          buffer.writeln(
            '  ${accessor.isGetter ? "get" : "set"} ${accessor.name}',
          );
        }
      }

      for (final fn in library.topLevelElements.whereType<FunctionElement>()) {
        buffer.writeln(_methodSig(fn));
      }
    }
  }

  File('codebase_signatures.md').writeAsStringSync(buffer.toString());
  print('Done → codebase_signatures.md');
}

String _methodSig(dynamic el) {
  // returnType name(params)
  return '  ${el.returnType} ${el.name}(${el.parameters.map((p) => '${p.type} ${p.name}').join(', ')})';
}
