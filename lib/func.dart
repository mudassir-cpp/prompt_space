import 'package:prompt_space/data_handler.dart';
import 'package:prompt_space/prompt.dart';

class PromptActions {
  PromptActions._();

  static final DB_Handler _repository = DB_Handler();

  /// Increments the global copy counter for a prompt and syncs it to Supabase.
  /// The UI uses this as the heart/copy action.
  static Future<Prompt> incrementCopies(Prompt prompt) {
    return _repository.incrementPromptCopies(prompt);
  }

  /// Saves or unsaves a prompt locally on this device.
  static Future<bool> toggleSavedLocally(Prompt prompt) async {
    final isSaved = await _repository.isPromptSaved(prompt);
    final nextSaved = !isSaved;
    await _repository.setSavedPrompt(prompt, nextSaved);
    return nextSaved;
  }

  static Future<bool> isSavedLocally(Prompt prompt) {
    return _repository.isPromptSaved(prompt);
  }
}
