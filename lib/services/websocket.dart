import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  StompClient? stompClient;
  Function(String)? onMessageReceived;

  void connect({Function(String)? onMessage}) {
    onMessageReceived = onMessage;
    stompClient = StompClient(
      config: StompConfig(
        url:
            'ws://103.63.25.133:8080/ws-nusa360', // ws://localhost:8080/ws-nusa360
        onConnect: _onConnectCallback,
        onWebSocketError: (dynamic error) {
          print('WebSocket Error: $error');
        },
        // Untuk Web, header opsional jika tidak perlu token
        // Jika pakai token, tambahkan header CORS di backend
        stompConnectHeaders: {},
        webSocketConnectHeaders: {},
        heartbeatIncoming: Duration(seconds: 0),
        heartbeatOutgoing: Duration(seconds: 0),
      ),
    );
    stompClient!.activate();
  }

  void _onConnectCallback(StompFrame frame) {
    print('WebSocket connected');
    stompClient!.subscribe(
      destination: '/topic/responses',
      callback: (frame) {
        final message = frame.body ?? '';
        if (onMessageReceived != null) {
          onMessageReceived!(message);
        }
      },
    );
  }

  void sendQuestion(String question) {
    if (stompClient != null && stompClient!.connected) {
      stompClient!.send(
        destination: '/app/askAvatar',
        body: '{"text": "$question"}',
      );
    }
  }

  void disconnect() {
    stompClient?.deactivate();
  }
}
