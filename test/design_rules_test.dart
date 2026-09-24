import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/theme/tokens.dart';

/// DESIGN_v2.md rules that are mechanical enough to check on the source.
/// A failure here is a review finding, not a style nit.
Iterable<File> _dartFiles(String dir) {
  return Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
}

String _rel(File f) => f.path.replaceAll('\\', '/');

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('no raw colours or magic numbers in features/', () {
    final features = _dartFiles('lib/features').toList();

    test('there are feature files to check', () {
      expect(features, isNotEmpty);
    });

    test('no hex colour literals and no Colors.* in features/', () {
      final offenders = <String>[];
      for (final f in features) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'Color\(0x|Colors\.').hasMatch(lines[i])) offenders.add('${_rel(f)}:${i + 1}');
        }
      }
      expect(offenders, isEmpty, reason: 'colours must come from AppColorTokens');
    });

    test('padding and gaps in features/ use the spacing scale', () {
      // Any EdgeInsets/SizedBox with a bare non-zero number instead of AppSpacing.*
      final magic = RegExp(
        r'(EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*\b[1-9]\d*(\.\d+)?\b)|(SizedBox\((width|height): [1-9]\d*)',
      );
      final offenders = <String>[];
      for (final f in features) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (magic.hasMatch(line) && !line.contains('AppSpacing')) offenders.add('${_rel(f)}:${i + 1}  ${line.trim()}');
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('things the design system removed stay removed', () {
    final all = _dartFiles('lib').toList();

    Map<String, List<String>> find(RegExp pattern, {List<String> except = const []}) {
      final hits = <String, List<String>>{};
      for (final f in all) {
        final path = _rel(f);
        if (except.any(path.endsWith)) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) hits.putIfAbsent(path, () => []).add('${i + 1}');
        }
      }
      return hits;
    }

    test('no Material AppBar (the header is AppHeaderBar)', () {
      expect(find(RegExp(r'\bAppBar\(')), isEmpty);
    });

    test('no Material NavigationBar (its active-icon fill is removed)', () {
      expect(find(RegExp(r'\bNavigationBar\(')), isEmpty);
    });

    test('no floating-label notch: labelText fields are gone', () {
      expect(find(RegExp(r'\blabelText:')), isEmpty);
    });

    test('OutlineInputBorder only where the theme defines the field border', () {
      expect(find(RegExp(r'\bOutlineInputBorder\('), except: ['core/theme/app_theme.dart']), isEmpty);
    });

    test('no pills, shadows, or gradients', () {
      expect(find(RegExp(r'StadiumBorder|BoxShadow|LinearGradient|RadialGradient')), isEmpty);
    });

    test('no hard-coded white text: text on accent comes from onAccent', () {
      expect(find(RegExp(r'Colors\.white')), isEmpty);
    });

    test('ColorScheme.fromSeed is not used', () {
      expect(find(RegExp(r'ColorScheme\.fromSeed')), isEmpty);
    });

    test('the retired v1 font families are gone', () {
      expect(find(RegExp(r"Literata|GolosText")), isEmpty);
    });
  });

  group('contrast (WCAG AA, 4.5:1)', () {
    final themes = {'light': AppColorTokens.light, 'dark': AppColorTokens.dark};

    for (final entry in themes.entries) {
      final t = entry.value;

      test('${entry.key}: muted on bg and on surface', () {
        expect(_contrast(t.muted, t.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(t.muted, t.surface), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: ink and body text on bg and surface', () {
        for (final text in [t.ink, t.body]) {
          expect(_contrast(text, t.bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(text, t.surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('${entry.key}: inkOn on the primary button (ink)', () {
        expect(_contrast(t.inkOn, t.ink), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: onAccent text on an accent fill', () {
        expect(_contrast(t.onAccent, t.accent), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: accent, success and danger on surface', () {
        for (final c in [t.accent, t.success, t.danger]) {
          expect(_contrast(c, t.surface), greaterThanOrEqualTo(4.5));
        }
      });
    }
  });
}
