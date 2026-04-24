import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messages = <Map<String, dynamic>>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'isBot': true,
      'text': 'Hello! 👋 I\'m HostelCare AI Assistant. I can help you with:\n\n• Troubleshooting issues\n• Filing complaints\n• Checking complaint status\n\nHow can I help you today?',
      'quickReplies': ['Electrical issue', 'Water problem', 'Internet down', 'Need cleaning', 'Submit complaint', 'Check status'],
    });
  }

  @override
  void dispose() { _inputCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'isBot': false, 'text': text});
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final res = await ApiService.post('${ApiConstants.chatbot}/message', {'message': text});
      final data = res['data'];
      setState(() {
        _messages.add({
          'isBot': true,
          'text': data['message'] ?? 'I\'m not sure about that. Could you rephrase?',
          'quickReplies': (data['quickReplies'] as List?)?.cast<String>(),
          'suggestedCategory': data['suggestedCategory'],
        });
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'isBot': true, 'text': 'Sorry, I\'m having trouble connecting. Please try again.'});
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.smart_toy_rounded, color: cs.primary, size: 20)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Online', style: TextStyle(fontSize: 11, color: Colors.green)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length && _sending) return _buildTypingIndicator();
              return _buildMessage(_messages[i]);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(child: TextField(
                controller: _inputCtrl,
                decoration: InputDecoration(hintText: 'Type your message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                onSubmitted: _sendMessage,
              )),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _sendMessage(_inputCtrl.text)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isBot = msg['isBot'] as bool;
    final cs = Theme.of(context).colorScheme;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
          Row(
            mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBot) ...[
                Container(width: 32, height: 32, decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.smart_toy, size: 18, color: cs.primary)),
                const SizedBox(width: 8),
              ],
              Flexible(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isBot ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F5)) : cs.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isBot ? 4 : 16), bottomRight: Radius.circular(isBot ? 16 : 4),
                  ),
                ),
                child: Text(msg['text'] ?? '', style: TextStyle(color: isBot ? null : Colors.white, height: 1.4)),
              )),
            ],
          ),
          if (isBot && msg['quickReplies'] != null) Padding(
            padding: const EdgeInsets.only(top: 8, left: 40),
            child: Wrap(spacing: 6, runSpacing: 6, children: (msg['quickReplies'] as List<String>).map((qr) => ActionChip(
              label: Text(qr, style: const TextStyle(fontSize: 12)),
              onPressed: () => _sendMessage(qr),
              side: BorderSide(color: cs.primary.withOpacity(0.3)),
            )).toList()),
          ),
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.smart_toy, size: 18, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 4), _dot(200), const SizedBox(width: 4), _dot(400),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (_, v, __) => Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), shape: BoxShape.circle)),
    );
  }
}
