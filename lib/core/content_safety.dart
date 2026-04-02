class ContentPolicyException implements Exception {
  const ContentPolicyException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _UnsafeRule {
  const _UnsafeRule({
    required this.category,
    required this.terms,
    this.allowCompactMatch = false,
  });

  final String category;
  final List<String> terms;
  final bool allowCompactMatch;
}

class ContentSafety {
  ContentSafety._();

  static const List<_UnsafeRule> _rules = [
    _UnsafeRule(
      category: 'abusive',
      terms: [
        'fuck you',
        'fucking',
        'bitch',
        'whore',
        'slut',
        'bastard',
        'asshole',
        'motherfucker',
        'son of a bitch',
        'idiot',
        'stupid',
        'dumbass',
        'clown',
        'loser',
        'قحبة',
        'قحبه',
        'زبي',
        'زب',
        'كس',
        'شرموطة',
        'شرموطه',
      ],
      allowCompactMatch: true,
    ),
    _UnsafeRule(
      category: 'hate',
      terms: [
        'nazi',
        'terrorist',
        'kill all',
        'go back to your country',
        'dirty arab',
        'dirty muslim',
        'ارهابي',
        'ارهابيين',
      ],
      allowCompactMatch: true,
    ),
    _UnsafeRule(
      category: 'sexual',
      terms: [
        'nude',
        'nudes',
        'porn',
        'porno',
        'sex video',
        'send nudes',
        'escort',
        'hooker',
        'anal',
        'blowjob',
        'dick pic',
        'vagina',
        'penis',
        'زب',
        'نيك',
      ],
      allowCompactMatch: true,
    ),
    _UnsafeRule(
      category: 'violence',
      terms: [
        'kill yourself',
        'kys',
        'suicide',
        'i will kill you',
        'murder',
        'bomb',
        'shoot you',
        'انتحر',
        'اقتل',
        'نقتلك',
      ],
      allowCompactMatch: true,
    ),
  ];

  static void validatePublicText(
    Iterable<String?> values, {
    String context = 'content',
  }) {
    for (final value in values) {
      final text = (value ?? '').trim();
      if (text.isEmpty) continue;

      final category = firstMatchedCategory(text);
      if (category != null) {
        throw ContentPolicyException(_messageFor(category, context));
      }
    }
  }

  static String? firstMatchedCategory(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    for (final rule in _rules) {
      for (final rawTerm in rule.terms) {
        final term = _normalize(rawTerm);
        if (term.isEmpty) continue;

        if (_containsNormalized(normalized, term)) {
          return rule.category;
        }

        if (rule.allowCompactMatch) {
          final compactTerm = term.replaceAll(RegExp(r'\s+'), '');
          if (compactTerm.length >= 4 && compact.contains(compactTerm)) {
            return rule.category;
          }
        }
      }
    }
    return null;
  }

  static String _messageFor(String category, String context) {
    switch (category) {
      case 'sexual':
        return 'Please remove sexual or explicit language before submitting this $context.';
      case 'violence':
        return 'Please remove violent or self-harm language before submitting this $context.';
      case 'hate':
        return 'Please remove hateful language before submitting this $context.';
      default:
        return 'Please remove abusive language before submitting this $context.';
    }
  }

  static String _normalize(String input) {
    const substitutions = {
      '@': 'a',
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      r'$': 's',
    };

    final lower = input.toLowerCase();
    final sb = StringBuffer();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      sb.write(substitutions[char] ?? char);
    }

    return sb
        .toString()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsNormalized(String normalized, String term) {
    if (term.contains(' ')) return normalized.contains(term);

    final escaped = RegExp.escape(term);
    return RegExp(
      '(^|\\s)$escaped(\\s|\$)',
      unicode: true,
    ).hasMatch(normalized);
  }
}
