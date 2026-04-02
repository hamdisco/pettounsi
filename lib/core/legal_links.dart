class LegalLinks {
  LegalLinks._();

  static const String appName = 'Pettounsi';
  static const String companyName = 'Pettounsi';

  static const String supportEmail = 'bmajdi92@gmail.com';
  static const String privacyPolicyUrl =
      'https://pettounsi.netlify.app/privacy';
  static const String termsUrl = 'https://pettounsi.netlify.app/terms';
  static const String accountDeletionUrl =
      'https://pettounsi.netlify.app/delete-account';

  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.trim().isNotEmpty;
  static bool get hasTermsUrl => termsUrl.trim().isNotEmpty;
  static bool get hasAccountDeletionUrl => accountDeletionUrl.trim().isNotEmpty;
}
