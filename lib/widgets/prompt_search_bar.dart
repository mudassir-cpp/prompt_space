import 'package:flutter/material.dart';

class PromptSearchBar extends StatelessWidget {
  const PromptSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search prompts, styles, tags',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.tune_rounded),
              )
            : IconButton(
                onPressed: () {
                  onClear();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: scheme.surface,
      ),
    );
  }
}
