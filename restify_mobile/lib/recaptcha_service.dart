import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class RecaptchaService {
  // Simpan controller dalam static variable agar tidak di-Garbage Collected (GC) saat proses berjalan
  static WebViewController? controller;

  static Future<String?> getToken() async {
    final completer = Completer<String?>();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (message) {
          if (!completer.isCompleted) {
            controller = null; // Bebaskan memory setelah selesai
            if (message.message.startsWith("error:")) {
              completer.complete(null);
            } else {
              completer.complete(message.message);
            }
          }
        },
      )
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <script>
              // Definisikan fungsi callback DI ATAS script loader 
              // untuk menghindari race condition (onload terpanggil sebelum fungsi di-parse)
              function onRecaptchaLoad() {
                grecaptcha.ready(function () {
                  grecaptcha.execute('6Le_NQktAAAAACGSaQhC9_rMYdzrbIzw1ylEbLBW', {action: 'login'})
                  .then(function(token) {
                    RecaptchaChannel.postMessage(token);
                  })
                  .catch(function(err) {
                    RecaptchaChannel.postMessage("error: " + err);
                  });
                });
              }
            </script>
            <script src="https://www.google.com/recaptcha/api.js?render=6Le_NQktAAAAACGSaQhC9_rMYdzrbIzw1ylEbLBW" onload="onRecaptchaLoad()"></script>
          </head>
          <body></body>
        </html>
      ''', baseUrl: 'http://localhost');

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        controller = null; // Bebaskan memory saat timeout
        return null;
      },
    );
  }
}