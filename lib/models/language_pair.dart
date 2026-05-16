enum Language {
  chinese('中文', 'zh', 'Chinese'),
  english('English', 'en', 'English'),
  french('Français', 'fr', 'French'),
  portuguese('Português', 'pt', 'Portuguese'),
  spanish('Español', 'es', 'Spanish'),
  japanese('日本語', 'ja', 'Japanese'),
  turkish('Türkçe', 'tr', 'Turkish'),
  russian('Русский', 'ru', 'Russian'),
  arabic('العربية', 'ar', 'Arabic'),
  korean('한국어', 'ko', 'Korean'),
  thai('ไทย', 'th', 'Thai'),
  italian('Italiano', 'it', 'Italian'),
  german('Deutsch', 'de', 'German'),
  vietnamese('Tiếng Việt', 'vi', 'Vietnamese'),
  malay('Bahasa Melayu', 'ms', 'Malay'),
  indonesian('Bahasa Indonesia', 'id', 'Indonesian'),
  filipino('Filipino', 'tl', 'Filipino'),
  hindi('हिन्दी', 'hi', 'Hindi'),
  polish('Polski', 'pl', 'Polish'),
  czech('Čeština', 'cs', 'Czech'),
  dutch('Nederlands', 'nl', 'Dutch'),
  khmer('ខ្មែរ', 'km', 'Khmer'),
  burmese('မြန်မာ', 'my', 'Burmese'),
  persian('فارسی', 'fa', 'Persian'),
  gujarati('ગુજરાતી', 'gu', 'Gujarati'),
  urdu('اردو', 'ur', 'Urdu'),
  telugu('తెలుగు', 'te', 'Telugu'),
  marathi('मराठी', 'mr', 'Marathi'),
  hebrew('עברית', 'he', 'Hebrew'),
  bengali('বাংলা', 'bn', 'Bengali'),
  tamil('தமிழ்', 'ta', 'Tamil'),
  ukrainian('Українська', 'uk', 'Ukrainian');

  const Language(this.displayName, this.code, this.englishName);
  final String displayName;
  final String code;
  final String englishName;
}

class LanguagePair {
  final Language source;
  final Language target;

  const LanguagePair(this.source, this.target);

  LanguagePair swapped() => LanguagePair(target, source);
}
