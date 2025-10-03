import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../profiles/domain/user.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';
  static const routeName = 'onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _roleController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _roleController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _submit(User baseUser) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updated = baseUser.copyWith(
        role: _roleController.text.trim().isEmpty ? baseUser.role : _roleController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? baseUser.bio : _bioController.text.trim(),
        statusMessage: _statusController.text.trim().isEmpty ? baseUser.statusMessage : _statusController.text.trim(),
      );
      await ref.read(authControllerProvider.notifier).completeOnboarding(updated);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      child: Text(user.name.characters.first.toUpperCase()),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  hintText: user.role ?? 'e.g. Engineering Manager',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _statusController,
                decoration: InputDecoration(
                  labelText: 'Status message',
                  hintText: user.statusMessage ?? 'What are you up to?',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: user.bio ?? 'Tell the team about yourself, skills, hobbies…',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : () => _submit(user),
                icon: const Icon(Icons.save_alt),
                label: const Text('Finish onboarding'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
