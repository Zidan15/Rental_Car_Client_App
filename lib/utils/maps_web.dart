import 'dart:html' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadGoogleMaps() async {
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('WARNING: GOOGLE_MAPS_API_KEY not found in .env');
    return;
  }

  // Check if script is already present
  if (html.document.getElementById('google-maps-sdk') != null) {
    return;
  }

  final script = html.ScriptElement()
    ..id = 'google-maps-sdk'
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places'
    ..async = true;

  html.document.head!.append(script);
  
  // Wait a bit for script to load? 
  // Google Maps JS API loads asynchronously. 
  // We rely on it being ready when the Map widget is mounted.
}
