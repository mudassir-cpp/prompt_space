import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prompt_space/main.dart';
import 'package:prompt_space/test_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (testMode) return TestAdIds.banner;
      return dotenv.get('prompt_space_banner');
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (testMode) return TestAdIds.interstitial;
      return dotenv.get('prompt_space_Interstitial');
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      if (testMode) return TestAdIds.interstitial;
      return dotenv.get('prompt_space_rewarded');
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
