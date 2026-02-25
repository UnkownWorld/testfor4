import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import '../models/provider_settings.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';

/// Chat screen for displaying and sending messages
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isGenerating = false;
  OpenAIService? _apiService;
  Message? _generatingMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _apiService?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final session = provider.currentSession;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: Text('No session selected')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${session.provider} • ${session.model}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            actions: [
              if (_isGenerating)
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _stopGeneration,
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessageList(provider),
              ),
              _buildInputArea(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _MessageBubble(
          message: message,
          onDelete: () => _deleteMessage(provider, message),
        );
      },
    );
  }

  Widget _buildInputArea(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(provider),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: _isGenerating ? null : () => _sendMessage(provider),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider provider) async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isGenerating) return;

    final session = provider.currentSession;
    if (session == null) return;

    final providerSettings = provider.getProvider(session.provider);
    if (providerSettings == null || !providerSettings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider not configured')),
      );
      return;
    }

    _messageController.clear();

    // Add user message
    await provider.addMessage(
      role: Message.roleUser,
      content: content,
    );

    // Create assistant message placeholder
    _generatingMessage = await provider.addMessage(
      role: Message.roleAssistant,
      content: '',
      aiProvider: session.provider,
      model: session.model,
    );

    setState(() => _isGenerating = true);

    // Build messages for API
    final messages = <Map<String, String>>[];
    
    if (session.systemPrompt != null && session.systemPrompt!.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': session.systemPrompt!,
      });
    }

    // Add recent messages (respecting maxContext)
    final recentMessages = provider.messages
        .where((m) => !m.generating && m.error == null)
        .toList();
    final startIndex = recentMessages.length > session.maxContext
        ? recentMessages.length - session.maxContext
        : 0;

    for (var i = startIndex; i < recentMessages.length; i++) {
      final m = recentMessages[i];
      messages.add({
        'role': m.role,
        'content': m.content,
      });
    }

    // Initialize API service
    _apiService = OpenAIService(providerSettings);

    // Send request
    final request = ChatRequest(
      model: session.model,
      messages: messages,
      temperature: session.temperature,
      topP: session.topP,
      maxTokens: session.maxTokens,
      stream: session.streaming,
    );

    String fullContent = '';
    
    _apiService!.chatCompletion(
      request,
      _ChatCallback(
        onStart: () {},
        onChunk: (chunk) {
          fullContent += chunk;
          if (_generatingMessage != null) {
            provider.updateMessage(
              _generatingMessage!.copyWith(
                content: fullContent,
                generating: true,
              ),
            );
          }
          _scrollToBottom();
        },
        onComplete: (response) {
          if (_generatingMessage != null) {
            provider.updateMessage(
              _generatingMessage!.copyWith(
                content: fullContent,
                generating: false,
                inputTokens: response.promptTokens,
                outputTokens: response.completionTokens,
                totalTokens: response.totalTokens,
                finishReason: response.finishReason,
              ),
            );
          }
          setState(() {
            _isGenerating = false;
            _generatingMessage = null;
          });
        },
        onError: (error) {
          if (_generatingMessage != null) {
            provider.updateMessage(
              _generatingMessage!.copyWith(
                generating: false,
                error: error,
              ),
            );
          }
          setState(() {
            _isGenerating = false;
            _generatingMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
      ),
      stream: session.streaming,
    );
  }

  void _stopGeneration() {
    _apiService?.cancel();
    setState(() {
      _isGenerating = false;
      _generatingMessage = null;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _deleteMessage(ChatProvider provider, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMessage(message);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasError = message.hasError;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasError)
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (message.generating)
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.content.isEmpty ? 'Thinking...' : 'Generating...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            if (message.content.isNotEmpty)
              isUser
                  ? Text(message.content)
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        // Handle link tap
                      },
                    ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.totalTokens != null)
                  Text(
                    '${message.totalTokens} tokens',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatCallback implements ChatCallback {
  final VoidCallback onStart;
  final void Function(String) onChunk;
  final void Function(ChatResponse) onComplete;
  final void Function(String) onError;

  _ChatCallback({
    required this.onStart,
    required this.onChunk,
    required this.onComplete,
    required this.onError,
  });

  @override
  void onStart() => onStart();

  @override
  void onChunk(String chunk) => onChunk(chunk);

  @override
  void onComplete(ChatResponse response) => onComplete(response);

  @override
  void onError(String error) => onError(error);
}
