import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/provider_settings.dart';
import '../providers/chat_provider.dart';

/// Settings screen for configuring AI providers
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'AI Providers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...provider.providers.map((p) => _ProviderCard(
                    settings: p,
                    onTap: () => _showProviderConfig(context, provider, p),
                  )),
              const SizedBox(height: 16),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chatbox AI',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A cross-platform AI chat application supporting multiple AI providers including OpenAI, Anthropic, OpenRouter, and Google Gemini.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProviderConfig(
    BuildContext context,
    ChatProvider provider,
    ProviderSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ProviderConfigDialog(
        settings: settings,
        onSave: (updated) {
          provider.updateProviderSettings(updated);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderSettings settings;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          _getProviderIcon(settings.provider),
          color: settings.isConfigured
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(settings.displayName),
        subtitle: Text(
          settings.isConfigured
              ? '${settings.models.length} models available'
              : 'Not configured',
          style: TextStyle(
            color: settings.isConfigured
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        trailing: Icon(
          settings.isConfigured ? Icons.check_circle : Icons.arrow_forward_ios,
          color: settings.isConfigured
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return Icons.smart_toy;
      case 'anthropic':
        return Icons.psychology;
      case 'openrouter':
        return Icons.route;
      case 'gemini':
        return Icons.diamond;
      default:
        return Icons.cloud;
    }
  }
}

class _ProviderConfigDialog extends StatefulWidget {
  final ProviderSettings settings;
  final void Function(ProviderSettings) onSave;

  const _ProviderConfigDialog({
    required this.settings,
    required this.onSave,
  });

  @override
  State<_ProviderConfigDialog> createState() => _ProviderConfigDialogState();
}

class _ProviderConfigDialogState extends State<_ProviderConfigDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _apiHostController;
  late TextEditingController _apiPathController;
  late TextEditingController _modelsController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.settings.apiKey ?? '');
    _apiHostController = TextEditingController(
      text: widget.settings.apiHost ?? ProviderSettings.getDefaultHost(widget.settings.provider),
    );
    _apiPathController = TextEditingController(text: widget.settings.apiPath ?? '/v1/chat/completions');
    _modelsController = TextEditingController(
      text: widget.settings.models.isNotEmpty
          ? widget.settings.models.join('\n')
          : ProviderSettings.getDefaultModels(widget.settings.provider).join('\n'),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiHostController.dispose();
    _apiPathController.dispose();
    _modelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure ${widget.settings.displayName}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  helperText: 'Your API key for authentication',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiHostController,
                decoration: const InputDecoration(
                  labelText: 'API Host',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., https://api.openai.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiPathController,
                decoration: const InputDecoration(
                  labelText: 'API Path',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., /v1/chat/completions',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Models (one per line)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter model IDs, one per line',
                ),
                maxLines: 5,
              ),
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final models = _modelsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = widget.settings.copyWith(
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
      apiHost: _apiHostController.text.trim().isEmpty ? null : _apiHostController.text.trim(),
      apiPath: _apiPathController.text.trim().isEmpty ? null : _apiPathController.text.trim(),
      models: models,
    );

    widget.onSave(updated);
  }
}
