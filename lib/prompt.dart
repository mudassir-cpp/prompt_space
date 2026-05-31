class Prompt {
  final int likes;
  final String prompt;
  final String img_url;
  final List<String> tags;

  const Prompt({
    required this.prompt,
    required this.likes,
    required this.img_url,
    required this.tags,
  });

  factory Prompt.fromJson(Map<String, dynamic> mp) {
    final data = Map<String, dynamic>.from((mp['data'] as Map?) ?? {});
    final tags = (data['tags'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];

    return Prompt(
      prompt: data['prompt']?.toString() ?? '',
      likes: (mp['likes'] as num?)?.toInt() ?? 0,
      img_url: data['img_url']?.toString() ?? '',
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'likes': likes,
      'data': <String, dynamic>{
        'prompt': prompt,
        'img_url': img_url,
        'tags': tags,
      },
    };
  }

  static List<Prompt> demoPrompts() {
    return const <Prompt>[
      Prompt(
        prompt:
            'A premium editorial prompt for a cinematic product mockup, soft daylight, subtle shadows, creamy neutrals, and a polished studio background.',
        likes: 312,
        img_url:
            'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=1200&q=80',
        tags: <String>['Product', 'Editorial', 'Studio'],
      ),
      Prompt(
        prompt:
            'Minimal portrait concept with warm tones, shallow depth of field, elegant composition, and a refined modern fashion aesthetic.',
        likes: 248,
        img_url:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1200&q=80',
        tags: <String>['Portrait', 'Minimal', 'Fashion'],
      ),
      Prompt(
        prompt:
            'High-end travel scene with moody lighting, layered mountain silhouettes, and a calm atmospheric palette for a premium discovery feed.',
        likes: 196,
        img_url:
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=80',
        tags: <String>['Travel', 'Landscape', 'Moody'],
      ),
      Prompt(
        prompt:
            'Modern creative workspace with tactile materials, soft contrast, and elegant styling designed for a clean startup brand story.',
        likes: 173,
        img_url:
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
        tags: <String>['Workspace', 'Startup', 'Modern'],
      ),
      Prompt(
        prompt:
            'Dreamy cinematic landscape prompt with subtle gradients, premium color grading, and a calm visual rhythm that feels highly curated.',
        likes: 221,
        img_url:
            'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=1200&q=80',
        tags: <String>['Cinematic', 'Landscape', 'Dreamy'],
      ),
    ];
  }

  String getImg() => img_url;

  String getPrompt() => prompt;

  String get heroTag => '${img_url.hashCode}_${prompt.hashCode}';

  String get displayTitle {
    final compact = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return 'Untitled prompt';
    }
    if (compact.length <= 72) {
      return compact;
    }
    return '${compact.substring(0, 69).trimRight()}...';
  }

  String get previewText {
    final compact = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return 'No prompt text available.';
    }
    if (compact.length <= 96) {
      return compact;
    }
    return '${compact.substring(0, 93).trimRight()}...';
  }
}
