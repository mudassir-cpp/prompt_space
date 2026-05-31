// This keeps prompt loading resilient by using cache first, then Supabase,
// and finally a polished in-app demo dataset when the backend is unavailable.
import 'dart:convert';

import 'package:prompt_space/prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DB_Handler {
  static const String _cacheKey = 'store';
  static const String _savedPromptsKey = 'saved_prompts';

  List<Prompt> data = [];
  SharedPreferences? pref;

  Future<List<Prompt>> getData() async {
    if (data.isNotEmpty) {
      update();
      return data;
    }

    pref ??= await SharedPreferences.getInstance();

    final cached = pref!.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        data = decoded
            .map(
              (item) => Prompt.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        if (data.isNotEmpty) {
          return data;
        }
      } catch (_) {
        // If cache is stale or corrupt, continue to the network layer.
      }
    }

    try {
      final response =
          await Supabase.instance.client.from('prompt').select('*');
      data = response
          .map<Prompt>((mp) => Prompt.fromJson(Map<String, dynamic>.from(mp)))
          .toList();

      if (data.isNotEmpty) {
        await _persist();
        return data;
      }
    } catch (_) {
      // Fall back to demo content below.
    }

    data = Prompt.demoPrompts();
    return data;
  }

  Future<void> update() async {
    try {
      final response =
          await Supabase.instance.client.from('prompt').select('*');
      final fresh = response
          .map<Prompt>((mp) => Prompt.fromJson(Map<String, dynamic>.from(mp)))
          .toList();

      if (fresh.isNotEmpty) {
        data = fresh;
        await _persist();
      }
    } catch (_) {
      // Intentionally silent. The cached/demo data already keeps the UI alive.
    }
  }

  Future<void> _persist() async {
    pref ??= await SharedPreferences.getInstance();
    await pref!.setString(
      _cacheKey,
      jsonEncode(data.map((prompt) => prompt.toJson()).toList()),
    );
  }

  Future<Set<String>> getSavedPromptKeys() async {
    pref ??= await SharedPreferences.getInstance();
    return pref!.getStringList(_savedPromptsKey)?.toSet() ?? <String>{};
  }

  Future<bool> isPromptSaved(Prompt prompt) async {
    final saved = await getSavedPromptKeys();
    return saved.contains(prompt.heroTag);
  }

  Future<void> setSavedPrompt(Prompt prompt, bool saved) async {
    pref ??= await SharedPreferences.getInstance();
    final savedPrompts =
        pref!.getStringList(_savedPromptsKey)?.toSet() ?? <String>{};

    if (saved) {
      savedPrompts.add(prompt.heroTag);
    } else {
      savedPrompts.remove(prompt.heroTag);
    }

    await pref!.setStringList(_savedPromptsKey, savedPrompts.toList());
  }

  Future<Prompt> incrementPromptCopies(Prompt prompt) async {
    final updatedPrompt = Prompt(
      prompt: prompt.prompt,
      likes: prompt.likes + 1,
      img_url: prompt.img_url,
      tags: prompt.tags,
    );

    try {
      await Supabase.instance.client
          .from('prompt')
          .update(<String, dynamic>{'likes': updatedPrompt.likes})
          .eq('data->>prompt', prompt.prompt)
          .eq('data->>img_url', prompt.img_url);
    } catch (_) {
      // Keep the UI usable even if the network write fails.
    }

    final index = data.indexWhere((item) => item.heroTag == prompt.heroTag);
    if (index != -1) {
      data[index] = updatedPrompt;
    } else {
      data.add(updatedPrompt);
    }

    await _persist();
    return updatedPrompt;
  }
}
