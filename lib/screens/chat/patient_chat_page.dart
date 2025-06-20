import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class PatientChatPage extends StatefulWidget {
  const PatientChatPage({Key? key}) : super(key: key);

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  String? patientId;
  List<Map<String, dynamic>> medici = [];
  Map<String, dynamic>? selectedMedic;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      patientId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      String? medicId = data['medicId'];
      if (medicId != null && medicId.isNotEmpty) {
        final medicDoc = await FirebaseFirestore.instance.collection('users').doc(medicId).get();
        if (medicDoc.exists) {
          final mdata = medicDoc.data() ?? {};
          setState(() {
            medici = [
              {
                'uid': medicDoc.id,
                'nume': mdata['nume'] ?? '',
                'prenume': mdata['prenume'] ?? '',
                'email': mdata['email'] ?? '',
                'specializare': mdata['specializare'] ?? '',
              }
            ];
          });
        }
      }
    }
  }

  void selectMedic(Map<String, dynamic> medic) {
    setState(() {
      selectedMedic = medic;
    });
  }

  void deselectMedic() {
    setState(() {
      selectedMedic = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedMedic == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('messages'.tr()),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: medici.isEmpty
            ? Center(
          child: Text(
            'no_doctor_found'.tr(),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
        )
            : ListView.builder(
          itemCount: medici.length,
          itemBuilder: (context, i) {
            final m = medici[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
                title: Text(
                  "Dr. ${m['nume']} ${m['prenume']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text((m['email'] ?? '') +
                    (m['specializare'] != null && m['specializare'] != ''
                        ? " (${m['specializare']})"
                        : "")),
                onTap: () => selectMedic(m),
              ),
            );
          },
        ),
      );
    } else {
      return _MedicChatView(
        medic: selectedMedic!,
        patientId: patientId!,
        onBack: deselectMedic,
      );
    }
  }
}

class _MedicChatView extends StatefulWidget {
  final Map<String, dynamic> medic;
  final String patientId;
  final VoidCallback onBack;

  const _MedicChatView({
    required this.medic,
    required this.patientId,
    required this.onBack,
  });

  @override
  State<_MedicChatView> createState() => _MedicChatViewState();
}

class _MedicChatViewState extends State<_MedicChatView> {
  final TextEditingController _controller = TextEditingController();
  String? _editingMessageId;
  String? _selectedMessageId;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatDocId = _chatId(widget.patientId, widget.medic['uid']);
    if (_editingMessageId != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .doc(_editingMessageId)
          .update({'message': text});
      setState(() {
        _editingMessageId = null;
      });
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .add({
        'senderId': widget.patientId,
        'senderRole': 'patient',
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    _controller.clear();
  }

  String _chatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return ids.join('_');
  }

  Future<void> _showEditDeleteDialog(BuildContext context, String messageId, String text, bool canEdit) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text('edit'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessageId = messageId;
                      _controller.text = text;
                      _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length));
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final chatDocId = _chatId(widget.patientId, widget.medic['uid']);
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatDocId)
                      .collection('messages')
                      .doc(messageId)
                      .delete();
                  if (_editingMessageId == messageId) {
                    setState(() {
                      _editingMessageId = null;
                      _controller.clear();
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text('close'.tr()),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatDocId = _chatId(widget.patientId, widget.medic['uid']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dr. ${widget.medic['nume']} ${widget.medic['prenume']}",
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.white),
          onPressed: widget.onBack,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.white),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatDocId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'no_messages'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isSentByMe =
                        data['senderId'] == widget.patientId && data['senderRole'] == 'patient';

                    final Color bubbleColor = isSentByMe
                        ? (isDark ? Colors.teal[700]! : Colors.teal)
                        : (isDark ? const Color(0xFF393939) : Colors.grey[300]!);
                    final Color textColor = isSentByMe ? Colors.white : (isDark ? Colors.white : Colors.black);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMessageId = _selectedMessageId == doc.id ? null : doc.id;
                        });
                      },
                      onLongPress: isSentByMe
                          ? () => _showEditDeleteDialog(context, doc.id, data['message'] ?? '', true)
                          : () => _showEditDeleteDialog(context, doc.id, data['message'] ?? '', false),
                      child: Align(
                        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isSentByMe ? 20 : 6),
                                  bottomRight: Radius.circular(isSentByMe ? 6 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                data['message'] ?? '',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            if (_selectedMessageId == doc.id)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
                                child: Text(
                                  'trimis_la'.tr(namedArgs: {'date': formatTimestamp(data['timestamp'])}),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: isDark ? const Color(0xFF232323) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'write_message'.tr(),
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF323232) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor, size: 28),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
