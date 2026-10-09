import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateSyntax', () {
    test('lookup returns correct syntax enum', () {
      expect(TemplateSyntax.lookup('hash'), TemplateSyntax.hash);
      expect(TemplateSyntax.lookup('HASH'), TemplateSyntax.hash);
      expect(TemplateSyntax.lookup('mustache'), TemplateSyntax.mustache);
      expect(TemplateSyntax.lookup('MUSTACHE'), TemplateSyntax.mustache);
      expect(TemplateSyntax.lookup('pipe'), TemplateSyntax.pipe);
      expect(TemplateSyntax.lookup('standard'), TemplateSyntax.standard);
    });

    test('lookup falls back to standard for unknown or null', () {
      expect(TemplateSyntax.lookup(null), TemplateSyntax.standard);
      expect(TemplateSyntax.lookup('unknown'), TemplateSyntax.standard);
      expect(TemplateSyntax.lookup(''), TemplateSyntax.standard);
    });

    test('syntax instances match expected ExpressionSyntax', () {
      expect(TemplateSyntax.hash.syntax, isA<HashExpressionSyntax>());
      expect(TemplateSyntax.mustache.syntax, isA<MustacheExpressionSyntax>());
      expect(TemplateSyntax.pipe.syntax, isA<PipeExpressionSyntax>());
      expect(TemplateSyntax.standard.syntax, isA<StandardExpressionSyntax>());
    });
  });
}
