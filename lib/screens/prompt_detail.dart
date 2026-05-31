import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';
import 'package:prompt_space/ad_helper.dart';
import 'package:prompt_space/data_handler.dart';
import 'package:prompt_space/func.dart';
import 'package:prompt_space/prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptDetail extends StatefulWidget {
  const PromptDetail({super.key});

  @override
  State<PromptDetail> createState() => _PromptDetailState();
}

class _PromptDetailState extends State<PromptDetail> {
  final DB_Handler _repository = DB_Handler();
  bool _isSaved = false;
  bool _didLoadPrompt = false;
  late Prompt _prompt;

  InterstitialAd? _interstitialAd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadPrompt) {
      return;
    }

    final arg = ModalRoute.of(context)?.settings.arguments;
    _prompt = arg is Prompt ? arg : Prompt.demoPrompts().first;
    _didLoadPrompt = true;
    _loadInteractions();
  }

  Future<void> _loadInteractions() async {
    final saved = await _repository.getSavedPromptKeys();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaved = saved.contains(_prompt.heroTag);
    });
  }

  void _copyPrompt(Prompt prompt) {
    Clipboard.setData(ClipboardData(text: prompt.getPrompt()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Prompt copied to clipboard')));
  }

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          logger.d('interstitial ad loaded!!!!!!');
        },
        onAdFailedToLoad: (err) {
          logger.e('Failed to load an interstitial ad: ${err.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showIntersitialAd() {
    logger.i('show interstitial: ${_interstitialAd != null}');
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: ((ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        }),
      );
      _interstitialAd!.show();
    } else {
      _loadInterstitialAd();
    }
  }

  Logger logger = Logger();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _copyPrompt(_prompt);
          // increment in supabase
          // SHOW

          // IF THIRD COPY THEN SHOW INTERSUTITIAL ad
          SharedPreferences pref = await SharedPreferences.getInstance();
          int? ncopied = pref.getInt('ncopied');
          logger.e(ncopied);
          if (ncopied == null || ncopied < 3) {
            // kch nhi krna
            if (ncopied == null) {
              pref.setInt('ncopied', 0);
            } else {
              pref.setInt('ncopied', ncopied + 1);
            }
          } else {
            pref.setInt('ncopied', 0);
            _showIntersitialAd();
          }
          // TODO if this image is not alrady + from this device record stored in shared pref then update supabase
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copy prompt'),
      ),
      body: _Backdrop(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: _GlassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _GlassButton(
                    icon: _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    active: _isSaved,
                    onTap: () {
                      PromptActions.toggleSavedLocally(_prompt).then((isSaved) {
                        if (!mounted) return;
                        setState(() {
                          _isSaved = isSaved;
                        });
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.55),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            theme.brightness == Brightness.dark ? 0.22 : 0.08,
                          ),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          Hero(
                            tag: _prompt.heroTag,
                            child: _NetworkImage(url: _prompt.getImg()),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.12),
                                    Colors.black.withOpacity(0.42),
                                  ],
                                  stops: const <double>[0.55, 0.82, 1.0],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _prompt.tags
                                      .map(
                                        (tag) => _TagChip(
                                          label: tag,
                                          inverted: true,
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _MiniStat(
                                      icon: Icons.favorite_rounded,
                                      value: '${_prompt.likes}',
                                    ),
                                    const SizedBox(width: 8),
                                    _MiniStat(
                                      icon: Icons.auto_awesome_rounded,
                                      value: 'Premium',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.55),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Prompt text',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _prompt.getPrompt(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ActionChip(
                              icon: _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              label: _isSaved ? 'Saved' : 'Save',
                              active: _isSaved,
                              onTap: () {
                                PromptActions.toggleSavedLocally(_prompt).then((
                                  isSaved,
                                ) {
                                  if (!mounted) return;
                                  setState(() {
                                    _isSaved = isSaved;
                                  });
                                });
                              },
                            ),
                            _ActionChip(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                // TODO Share with image too

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share action coming soon'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withOpacity(0.68),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Tip: open this screen when you want the full prompt, then copy it into your workflow or modify it for a new generation.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            scheme.surface,
            scheme.surface.withOpacity(0.98),
            scheme.surfaceContainerHighest.withOpacity(0.18),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.10 : 0.16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: active ? scheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.inverted = false});

  final String label;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.4,
              )
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: inverted
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.18,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary.withOpacity(0.12) : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      errorWidget: (context, url, error) => Container(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
          size: 42,
        ),
      ),
    );
  }
}
