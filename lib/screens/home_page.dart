import 'package:flutter/material.dart';
import 'package:flutter_masonry_view/flutter_masonry_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:prompt_space/ad_helper.dart';
import 'package:prompt_space/data_handler.dart';
import 'package:prompt_space/func.dart';
import 'package:prompt_space/prompt.dart';
import 'package:prompt_space/routes.dart';
import 'package:prompt_space/widgets/prompt_bottom_nav.dart';
import 'package:prompt_space/widgets/prompt_card.dart';
import 'package:prompt_space/widgets/prompt_category_chips.dart';
import 'package:prompt_space/widgets/prompt_empty_state.dart';
import 'package:prompt_space/widgets/prompt_search_bar.dart';
import 'package:prompt_space/widgets/prompt_section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.forceDemo = false});

  final bool forceDemo;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BannerAd? _bannerAd;

  final DB_Handler _repository = DB_Handler();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Prompt>> _promptsFuture;

  final Set<String> _copiedPrompts = <String>{};
  final Set<String> _savedPrompts = <String>{};

  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _promptsFuture = widget.forceDemo
        ? Future<List<Prompt>>.value(Prompt.demoPrompts())
        : _repository.getData();
    _loadPromptInteractions();
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromptInteractions() async {
    final saved = await _repository.getSavedPromptKeys();
    if (!mounted) return;
    setState(() {
      _savedPrompts
        ..clear()
        ..addAll(saved);
    });
  }

  Future<void> _refreshPrompts() async {
    setState(() {
      _promptsFuture = widget.forceDemo
          ? Future<List<Prompt>>.value(Prompt.demoPrompts())
          : _repository.getData();
    });
    await _promptsFuture;
  }

  Future<void> _copyPrompt(Prompt prompt) async {
    final updatedPrompt = await PromptActions.incrementCopies(prompt);
    if (!mounted) return;
    setState(() {
      _copiedPrompts.add(updatedPrompt.heroTag);
    });
    await _refreshPrompts();
  }

  void _toggleSave(Prompt prompt) {
    PromptActions.toggleSavedLocally(prompt).then((isSaved) {
      if (!mounted) return;
      setState(() {
        if (isSaved) {
          _savedPrompts.add(prompt.heroTag);
        } else {
          _savedPrompts.remove(prompt.heroTag);
        }
      });
    });
  }

  List<Prompt> _filterPrompts(List<Prompt> prompts) {
    final query = _searchQuery.trim().toLowerCase();
    final selectedCategory = _selectedCategory.toLowerCase();

    return prompts.where((prompt) {
      final matchesTab =
          _selectedTab != 1 || _savedPrompts.contains(prompt.heroTag);
      final matchesCategory =
          _selectedCategory == 'All' ||
          prompt.tags.any((tag) => tag.toLowerCase() == selectedCategory);
      final matchesQuery =
          query.isEmpty ||
          <String>[
            prompt.prompt,
            ...prompt.tags,
          ].join(' ').toLowerCase().contains(query);

      return matchesTab && matchesCategory && matchesQuery;
    }).toList();
  }

  List<String> _categories(List<Prompt> prompts) {
    final counts = <String, int>{};
    for (final prompt in prompts) {
      for (final tag in prompt.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }

    final tags = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return <String>['All', ...tags.take(8).map((entry) => entry.key)];
  }

  Future<void> _openPrompt(Prompt prompt) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.prompt_detail,
      arguments: prompt,
    );
    if (!mounted) return;
    await _loadPromptInteractions();
    await _refreshPrompts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prompt Space',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _selectedTab = 1);
              },
              icon: Icon(
                _savedPrompts.isEmpty
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_rounded,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PromptBottomNav(
        selectedIndex: _selectedTab,
        onChanged: (index) => setState(() => _selectedTab = index),
      ),
      
      body: FutureBuilder<List<Prompt>>(
        future: _promptsFuture,
        builder: (context, snapshot) {
          final prompts = snapshot.data ?? Prompt.demoPrompts();
          final loading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final visiblePrompts = _filterPrompts(prompts);

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(

                    onRefresh: _refreshPrompts,

                    
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          PromptSearchBar(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            onClear: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          PromptCategoryChips(
                            categories: _categories(prompts),
                            selectedCategory: _selectedCategory,
                            onChanged: (category) {
                              setState(() => _selectedCategory = category);
                            },
                          ),
                          const SizedBox(height: 16),
                          PromptSectionHeader(
                            title:
                                _selectedTab == 1 ? 'Saved prompts' : 'Discover',
                            subtitle: _selectedTab == 1
                                ? 'Only the prompts you saved'
                                : 'Clean, tall cards with less text and more image space',
                          ),
                          const SizedBox(height: 12),
                          if (loading)
                            Column(
                              children: List.generate(
                                4,
                                (index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 14),
                                  child: PromptCardSkeleton(),
                                ),
                              ),
                            )
                          else if (visiblePrompts.isEmpty)
                            PromptEmptyState(
                              title: _selectedTab == 1
                                  ? 'No saved prompts yet'
                                  : 'No prompts found',
                              subtitle: _selectedTab == 1
                                  ? 'Tap the save button on any card to keep it here.'
                                  : 'Try a different search or category.',
                              actionLabel: 'Clear filters',
                              onActionTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                });
                              },
                            )
                          else
                            MasonryView(
                              listOfItem: visiblePrompts,
                              numberOfColumn:
                                  MediaQuery.of(context).size.width >= 700
                                      ? 3
                                      : 2,
                              itemBuilder: (item) {
                                final prompt = item as Prompt;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: PromptCard(
                                    prompt: prompt,
                                    isCopied:
                                        _copiedPrompts.contains(prompt.heroTag),
                                    isSaved:
                                        _savedPrompts.contains(prompt.heroTag),
                                    onTap: () => _openPrompt(prompt),
                                    onCopy: () => _copyPrompt(prompt),
                                    onSave: () => _toggleSave(prompt),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_bannerAd != null)
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: _bannerAd!.size.height.toDouble(),
                      child: Center(
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
