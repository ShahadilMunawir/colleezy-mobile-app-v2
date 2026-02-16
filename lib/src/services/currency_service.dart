import 'package:flutter/foundation.dart';

class CurrencyService {
  CurrencyService._privateConstructor();
  static final CurrencyService instance = CurrencyService._privateConstructor();
  final ValueNotifier<String> currentCurrency = ValueNotifier<String>('INR');
  void setCurrency(String c) => currentCurrency.value = (c ?? 'INR').toUpperCase();
}

