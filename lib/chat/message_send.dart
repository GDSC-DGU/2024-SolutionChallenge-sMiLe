import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/palette.dart';
import 'chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewMessage extends StatefulWidget {
  const NewMessage({Key? key}) : super(key: key);

  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();
  late Stream<QuerySnapshot> chatDocs;
  late String _userInfo ="";

  getUser() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _userInfo = _prefs.getString("userInfo")!;
    chatDocs = FirebaseFirestore.instance.collection('chat').orderBy('time', descending: true).snapshots();
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    FocusScope.of(context).unfocus();
    print('User: ${_controller.text}');
    FirebaseFirestore.instance.collection('chat').add({
      'chat': _controller.text,
      'isUser': true,
      'userInfo': _userInfo,
      'time': Timestamp.now(),
    });
    _sendChatRequest();
    _controller.clear();
  }

  // 입력받은 메세지를 api로 전송하여 답변을 만들어서 firestore에 저장
  void _sendChatRequest() async {
    print('Sending a chat request...');
    final url = Uri.parse('http://210.94.179.18:9068/chat');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'userInput': _controller.text});
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      print('Chat request sent successfully');
    } else {
      print('Failed to send chat request');
    }
    print('Response: ${jsonDecode(response.body)['response']}');
    var chat_text = jsonDecode(response.body)['response'];
    if (chat_text == null) {
      chat_text = 'Sorry, I cannot understand...';
    }
    FirebaseFirestore.instance.collection('chat').add({
      'chat': chat_text,
      'isUser': false,
      'userInfo': _userInfo,
      'time': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Type Message...'),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send),
            color: Palette.bgColor,
          ),
        ],
      ),
    );
  }
}
