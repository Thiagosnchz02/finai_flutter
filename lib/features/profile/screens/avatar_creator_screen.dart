import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  bool _isLoading = true;

  // URL del creador de avatares de Ready Player Me.
  // Puedes personalizarla más adelante desde tu cuenta de RPM.
  final String rpmCreatorUrl = 'https://demo.readyplayer.me/es/avatar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea tu Avatar'),
        // Botón para cerrar el WebView
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(rpmCreatorUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {

              // Añadimos el "puente" entre JavaScript y Flutter.
              // El nombre 'rpmAvatarExported' debe coincidir con el que llamamos desde JS.
              controller.addJavaScriptHandler(
                handlerName: 'rpmAvatarExported',
                callback: (args) {
                  // args[0] contendrá la URL del avatar .glb
                  if (args.isNotEmpty && args[0] is String) {
                    final avatarUrl = args[0] as String;
                    print('Avatar URL recibido desde RPM: $avatarUrl');
                    // Devolvemos la URL a la pantalla anterior (ProfileScreen)
                    Navigator.of(context).pop(avatarUrl);
                  }
                },
              );
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              // Inyectamos nuestro script para escuchar el evento de RPM
              _injectJavaScriptListener(controller);
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
          // Muestra un indicador de carga mientras el WebView se prepara.
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  /// Inyecta un script en la página para escuchar el evento 'v1.avatar.exported'
  /// y enviar la URL del avatar a Flutter a través de nuestro handler.
  void _injectJavaScriptListener(InAppWebViewController controller) {
    const jsListener = '''
      window.addEventListener('v1.avatar.exported', (event) => {
        const avatarUrl = event.data.url;
        // Llama a nuestro handler 'rpmAvatarExported' definido en Flutter
        window.flutter_inappwebview.callHandler('rpmAvatarExported', avatarUrl);
      });
    ''';
    controller.evaluateJavascript(source: jsListener);
  }
}
