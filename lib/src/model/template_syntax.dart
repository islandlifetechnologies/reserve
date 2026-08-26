import 'package:template_expressions/template_expressions.dart';

enum TemplateSyntax {
  hash(HashExpressionSyntax()),
  mustache(MustacheExpressionSyntax()),
  standard(StandardExpressionSyntax()),
  pipe(PipeExpressionSyntax());

  const TemplateSyntax(this.syntax);

  final ExpressionSyntax syntax;

  static TemplateSyntax lookup(String? value) =>
      values.where((s) => s.name == value?.toLowerCase()).firstOrNull ??
      standard;
}
