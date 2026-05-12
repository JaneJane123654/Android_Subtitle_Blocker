import 'package:subtitle_blocker_flutter_refactor/features/updates/domain/updates_domain.dart';
import 'package:test/test.dart';

void main() {
  group('VersionNameComparator', () {
    test('compare_handlesPrefixAndSegments', () {
      expect(VersionNameComparator.compare('v1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionNameComparator.compare('1.2', '1.2.0'), 0);
      expect(VersionNameComparator.compare('2.0.0', '1.9.9'), greaterThan(0));
      expect(VersionNameComparator.compare('1.0.0', '1.0.1'), lessThan(0));
    });

    test('normalize_removesQualifier', () {
      expect(VersionNameComparator.normalize('v1.3.2-beta+12'), '1.3.2');
      expect(VersionNameComparator.normalize(''), '0');
    });

    test('normalize_stripsAnyLeadingNonDigitPrefix', () {
      expect(VersionNameComparator.normalize('release-2.0'), '2.0');
      expect(VersionNameComparator.normalize('  build_10.4+7'), '10.4');
    });

    test('normalize_handlesNullBlankAndTextOnlyValuesAsZero', () {
      expect(VersionNameComparator.normalize(null), '0');
      expect(VersionNameComparator.normalize('   '), '0');
      expect(VersionNameComparator.normalize('beta'), '0');
    });

    test('compare_treatsMalformedFragmentsAsZero', () {
      expect(VersionNameComparator.compare('1.a.3', '1.0.3'), 0);
      expect(VersionNameComparator.compare('1..2', '1.0.2'), 0);
      expect(VersionNameComparator.compare('not-a-version', '0'), 0);
    });

    test('compare_extractsDigitsInsideMixedFragmentsLikeLegacyRegex', () {
      expect(VersionNameComparator.compare('1.2b.3', '1.2.3'), 0);
      expect(VersionNameComparator.compare('1.rc2.3', '1.2.3'), 0);
    });

    test('isNewer_returnsTrueOnlyWhenCandidateComparesHigher', () {
      expect(VersionNameComparator.isNewer('v1.2.4', '1.2.3'), isTrue);
      expect(VersionNameComparator.isNewer('1.2.3-beta', '1.2.3'), isFalse);
      expect(VersionNameComparator.isNewer(null, '0.0.1'), isFalse);
    });
  });
}
