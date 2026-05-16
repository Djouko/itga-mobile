import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/utilities/firebase_const.dart';

void main() {
  test('ChatMessage maps API message types to enum values', () {
    expect(ChatMessage(msgType: 'TEXT').msgType, MessageType.text);
    expect(ChatMessage(msgType: 'IMAGE').msgType, MessageType.image);
    expect(ChatMessage(msgType: 'VIDEO').msgType, MessageType.video);
  });

  testWidgets('mobile app test harness renders a stable shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: MyScrollBehavior(),
            child: child!,
          );
        },
        home: const Scaffold(body: Text('ITGA')),
      ),
    );

    expect(find.text('ITGA'), findsOneWidget);
  });
}
