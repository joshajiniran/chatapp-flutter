import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _store = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  String messageText;
  Timestamp timestamp;

  final messageTextController = TextEditingController();

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) loggedInUser = user;
      print(loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

  // void getMessages() async {
  //   var messages = await _store.collection('messages').getDocuments();
  //   for (var message in messages.documents) {
  //     print(message.data);
  //   }
  // }

  void messageStream() async {
    await for (var snapshot in _store.collection('messages').snapshots()) {
      for (var message in snapshot.documents) print(message.data);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                //Implement logout functionality
                await _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      timestamp = Timestamp.now();
                      if (messageTextController.text.isNotEmpty) {
                        _store.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser.email,
                          'timestamp': timestamp,
                        });
                        messageTextController.clear();
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe, this.timestamp});

  final String sender;
  final String text;
  final bool isMe;
  final Timestamp timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('$sender>${timestamp.toDate()}',
                style: TextStyle(fontSize: 14.0)),
          ),
          Material(
            elevation: 6.0,
            color: isMe ? Colors.lightBlueAccent : Colors.blueGrey[50],
            borderRadius: isMe
                ? BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(0.0),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    topLeft: Radius.circular(0.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Text(
                '$text',
                style: TextStyle(
                    fontSize: 16.0, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _store.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        } else {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messageWidgets = [];
          for (var message in messages) {
            final messageText = message.data['text'];
            final messageSender = message.data['sender'];
            final timestamp = message.data['timestamp'];

            final messageWidget = MessageBubble(
              text: messageText,
              sender: messageSender,
              isMe: messageSender == loggedInUser.email,
              timestamp: timestamp,
            );
            messageWidgets.add(messageWidget);
          }

          return Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageWidgets,
              physics: BouncingScrollPhysics(),
              reverse: true,
            ),
          );
        }
      },
    );
  }
}
