import 'package:colleezy/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env if it exists (copy from .env.example if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not found - app will use fallback values (e.g. ApiService.baseUrl)
  }
  await Firebase.initializeApp();
  runApp(const ColleezyApp());
}