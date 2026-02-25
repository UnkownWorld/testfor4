import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/provider_settings.dart';

/// Dialog for creating a new chat session
class NewChatDialog extends StatefulWidget {
  final List<ProviderSettings> providers;
  final void Function(Session) onCreated;

  const NewChatDialog({
    super.key,
    required this.providers,
    required this.onCreated,
  });

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  late ProviderSettings _selectedProvider;
  late String _selectedModel;
  
  final _nameController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _maxContextController = TextEditingController(text: '20');
  final _maxTokensController = TextEditingController(text: '4096');
  
  double _temperature = 0.7;
  double _topP = 1.0;
  bool _streaming = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.providers.first;
    _selectedModel = _selectedProvider.models.isNotEmpty
        ? _selectedProvider.models.first
        : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    _maxContextController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Chat'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Chat Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Provider selection
              DropdownButtonFormField<ProviderSettings>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
                items: widget.providers.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProvider = value;
                      _selectedModel = value.models.isNotEmpty
                          ? value.models.first
                          : '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Model selection
              DropdownButtonFormField<String>(
                value: _selectedModel.isEmpty ? null : _selectedModel,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                items: _selectedProvider.models.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Advanced settings toggle
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Row(
                  children: [
                    Icon(_showAdvanced
                        ? Icons.expand_less
                        : Icons.expand_more),
                    const SizedBox(width: 8),
                    const Text('Advanced Settings'),
                  ],
                ),
              ),
              
              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                
                // System prompt
                TextField(
                  controller: _systemPromptController,
                  decoration: const InputDecoration(
                    labelText: 'System Prompt (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Temperature
                Row(
                  children: [
                    const Text('Temperature'),
                    Expanded(
                      child: Slider(
                        value: _temperature,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        label: _temperature.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _temperature = value);
                        },
                      ),
                    ),
                    Text(_temperature.toStringAsFixed(1)),
                  ],
                ),
                
                // Top P
                Row(
                  children: [
                    const Text('Top P'),
                    Expanded(
                      child: Slider(
                        value: _topP,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        label: _topP.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() => _topP = value);
                        },
                      ),
                    ),
                    Text(_topP.toStringAsFixed(2)),
                  ],
                ),
                
                // Max context and tokens
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxContextController,
                        decoration: const InputDecoration(
                          labelText: 'Max Context',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxTokensController,
                        decoration: const InputDecoration(
                          labelText: 'Max Tokens',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Streaming toggle
                SwitchListTile(
                  title: const Text('Enable Streaming'),
                  value: _streaming,
                  onChanged: (value) {
                    setState(() => _streaming = value);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _createChat,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createChat() {
    final name = _nameController.text.trim().isEmpty
        ? 'New Chat'
        : _nameController.text.trim();
    
    final maxContext = int.tryParse(_maxContextController.text) ?? 20;
    final maxTokens = int.tryParse(_maxTokensController.text) ?? 4096;
    
    final session = Session(
      name: name,
      provider: _selectedProvider.provider,
      model: _selectedModel,
      systemPrompt: _systemPromptController.text.trim().isEmpty
          ? null
          : _systemPromptController.text.trim(),
      temperature: _temperature,
      topP: _topP,
      maxContext: maxContext,
      maxTokens: maxTokens,
      streaming: _streaming,
    );
    
    widget.onCreated(session);
  }
}
