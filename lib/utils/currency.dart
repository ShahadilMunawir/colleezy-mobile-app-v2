import 'package:intl/intl.dart';

const Map<String, String> currencySymbols = {
  'AED': 'د.إ',
  'AFN': '؋',
  'ALL': 'L',
  'AMD': '֏',
  'ARS': '\$',
  'AUD': '\$',
  'BDT': '৳',
  'BHD': '.د.ب',
  'BND': '\$',
  'BRL': 'R\$',
  'CAD': '\$',
  'CHF': 'CHF',
  'CNY': '¥',
  'CZK': 'Kč',
  'DKK': 'kr',
  'EGP': '£',
  'EUR': '€',
  'GBP': '£',
  'GHS': '₵',
  'HKD': '\$',
  'HUF': 'Ft',
  'IDR': 'Rp',
  'ILS': '₪',
  'INR': '₹',
  'JPY': '¥',
  'KES': 'KSh',
  'KRW': '₩',
  'KWD': 'د.ك',
  'LKR': '₨',
  'MAD': 'د.م.',
  'MUR': '₨',
  'MXN': '\$',
  'MYR': 'RM',
  'NGN': '₦',
  'NOK': 'kr',
  'NZD': '\$',
  'PHP': '₱',
  'PKR': '₨',
  'PLN': 'zł',
  'QAR': '﷼',
  'RUB': '₽',
  'SAR': '﷼',
  'SEK': 'kr',
  'SGD': '\$',
  'THB': '฿',
  'TND': 'د.ت',
  'TRY': '₺',
  'TWD': 'NT\$',
  'UGX': 'USh',
  'USD': '\$',
  'VND': '₫',
  'ZAR': 'R',
};

String formatCurrency(double amount, String code) {
  final upper = (code ?? 'INR').toUpperCase();
  final symbol = currencySymbols[upper] ?? upper;
  // Use NumberFormat for grouping and 2 decimal places
  final formatter = NumberFormat('#,##0.00');
  return '$symbol${formatter.format(amount)}';
}

