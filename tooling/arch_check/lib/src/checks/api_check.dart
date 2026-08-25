import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../model/violation.dart';
import '../rules/rule_set.dart';
import '../source_index.dart';
import 'check.dart';

/// Section 5: the ambient APIs a deterministic test suite cannot survive, and
/// the throw that escapes a port.
///
/// Matched against the parsed AST, never against raw text. Section 5 of the
/// dependency rules records both reasons: a doc comment quoting the rule it
/// explains trips a text search, and a regex whose dot is unescaped makes
/// `DateTime.now()` match the declaration `DateTime now()`. Every occurrence
/// of `DateTime.now()` in this workspace today is inside a comment explaining
/// why it is banned.
///
/// Generated files are exempt. A `DateTime` in generated output is not the
/// developer's choice, and the fix would have to be made in a file that must
/// never be hand-edited.
final class ApiCheck implements Check {
  /// Creates the section 5 check.
  const ApiCheck();

  @override
  String get name => 'forbidden APIs (section 5)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    final rules = context.rules.forbiddenApis;
    final calleeRules = rules.rules
        .where((rule) => rule.kind == ApiRuleKind.callee)
        .toList();
    final throwRules = rules.rules
        .where((rule) => rule.kind == ApiRuleKind.throwInResultReturningMember)
        .toList();

    for (final package in context.workspace.packages) {
      if (rules.exceptTypes.contains(package.type)) continue;
      for (final file
          in context.sources.of(package).inDirectories(rules.scan)) {
        if (context.rules.codegen.isGenerated(file.fileName)) continue;

        for (final rule in calleeRules) {
          final visitor = _CalleeVisitor(rule.callees);
          file.unit.accept(visitor);
          for (final hit in visitor.hits) {
            yield Violation(
              code: rule.code,
              location: _at(package.relativePath, file, hit.offset),
              what: 'calls ${hit.callee}(...)',
              remedy: context.rules.remedyFor(rule.code),
            );
          }
        }

        for (final rule in throwRules) {
          final visitor = _ThrowInResultVisitor(rule.resultType);
          file.unit.accept(visitor);
          for (final hit in visitor.hits) {
            yield Violation(
              code: rule.code,
              location: _at(package.relativePath, file, hit.offset),
              what:
                  '${hit.member} returns ${hit.returnType} and throws on '
                  'line ${file.lineOf(hit.offset)}',
              remedy: context.rules.remedyFor(rule.code),
            );
          }
        }
      }
    }
  }

  ViolationLocation _at(String package, SourceFile file, int offset) =>
      ViolationLocation(
        package: package,
        file: file.relativePath,
        line: file.lineOf(offset),
      );
}

/// Collects invocations whose textual callee is on a watch list.
///
/// The callee is built from syntax alone: the constructor name of an explicit
/// instance creation, `target.method` when the target is a plain identifier or
/// a prefixed one, and the bare name for an unqualified call. A call through
/// an expression — `factory().now()` — produces no callee at all, which is
/// what keeps `clock.now()` and `sink.print()` from matching.
final class _CalleeVisitor extends RecursiveAstVisitor<void> {
  _CalleeVisitor(this.watched);

  final Set<String> watched;
  final List<({String callee, int offset})> hits = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final callee = _calleeOf(node);
    if (callee != null && watched.contains(callee)) {
      hits.add((callee: callee, offset: node.offset));
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final callee = node.constructorName.toSource();
    if (watched.contains(callee)) {
      hits.add((callee: callee, offset: node.offset));
    }
    super.visitInstanceCreationExpression(node);
  }

  String? _calleeOf(MethodInvocation node) {
    final target = node.target;
    return switch (target) {
      null => node.methodName.name,
      SimpleIdentifier(:final name) => '$name.${node.methodName.name}',
      PrefixedIdentifier(:final prefix, :final identifier) =>
        '${prefix.name}.${identifier.name}.${node.methodName.name}',
      _ => null,
    };
  }
}

/// Finds a `throw` or `rethrow` inside a member that promised a `Result`.
///
/// The return type is read syntactically, so `Result<T, F>`,
/// `Future<Result<T, F>>`, `FutureOr<...>` and `Stream<...>` are all covered
/// without resolution. The approximation it accepts: a throw inside a closure
/// nested in such a member counts too. That is the safe direction — a closure
/// that throws inside an adapter is almost always the same mistake one level
/// down.
final class _ThrowInResultVisitor extends RecursiveAstVisitor<void> {
  _ThrowInResultVisitor(this.resultType);

  final String resultType;
  final List<({String member, String returnType, int offset})> hits = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _inspect(
      name: node.name.lexeme,
      returnType: node.returnType,
      body: node.body,
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _inspect(
      name: node.name.lexeme,
      returnType: node.returnType,
      body: node.functionExpression.body,
    );
    super.visitFunctionDeclaration(node);
  }

  void _inspect({
    required String name,
    required TypeAnnotation? returnType,
    required FunctionBody body,
  }) {
    if (returnType == null) return;
    final rendered = returnType.toSource();
    if (!rendered.contains('$resultType<')) return;

    final throws = _ThrowFinder();
    body.accept(throws);
    for (final offset in throws.offsets) {
      hits.add((member: name, returnType: rendered, offset: offset));
    }
  }
}

final class _ThrowFinder extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  @override
  void visitThrowExpression(ThrowExpression node) {
    offsets.add(node.offset);
    super.visitThrowExpression(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    offsets.add(node.offset);
    super.visitRethrowExpression(node);
  }
}
