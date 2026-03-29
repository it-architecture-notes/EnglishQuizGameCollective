import 'package:flutter/material.dart';

import '../../models/story_config.dart';
import '../transitions/custom_page_routes.dart';
import 'story_templates/story_template_a.dart';
import 'story_templates/story_template_b.dart';
import 'story_templates/story_template_c.dart';

class StoryOverlayScreen extends StatefulWidget {
  const StoryOverlayScreen({
    super.key,
    required this.page,
    required this.template,
    required this.languageCode,
    required this.continueLabel,
    required this.congratulationsLabel,
    this.isFinalPage = false,
  });

  final StoryPageConfig page;
  final StoryTemplateConfig? template;
  final String languageCode;
  final String continueLabel;
  final String congratulationsLabel;
  final bool isFinalPage;

  static Future<void> show(
    BuildContext context, {
    required StoryPageConfig page,
    required StoryTemplateConfig? template,
    required String languageCode,
    required String continueLabel,
    required String congratulationsLabel,
    bool isFinalPage = false,
  }) {
    return Navigator.of(context).push<void>(
      popFadeRoute(
        StoryOverlayScreen(
          page: page,
          template: template,
          languageCode: languageCode,
          continueLabel: continueLabel,
          congratulationsLabel: congratulationsLabel,
          isFinalPage: isFinalPage,
        ),
      ),
    );
  }

  @override
  State<StoryOverlayScreen> createState() => _StoryOverlayScreenState();
}

class _StoryOverlayScreenState extends State<StoryOverlayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeOut),
    );
    if (widget.isFinalPage) {
      _celebrationController.forward();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (widget.isFinalPage) ...[
                ScaleTransition(
                  scale: _celebrationScale,
                  child: Text(
                    widget.congratulationsLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: _buildTemplate(
                          context,
                          scrollViewportHeight: constraints.maxHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.continueLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplate(
    BuildContext context, {
    double? scrollViewportHeight,
  }) {
    return switch (widget.template?.layout) {
      'scene_animation_dialogues' => StoryTemplateB(
          page: widget.page,
          languageCode: widget.languageCode,
        ),
      'animation_only' => _buildAnimationOnly(context),
      'scene_story_text' => StoryTemplateC(
          page: widget.page,
          languageCode: widget.languageCode,
          scrollViewportHeight: scrollViewportHeight,
        ),
      _ => StoryTemplateA(
          page: widget.page,
          languageCode: widget.languageCode,
          scrollViewportHeight: scrollViewportHeight,
        ),
    };
  }

  Widget _buildAnimationOnly(BuildContext context) {
    final animationName = widget.page.pageAnimationListForTemplate.isEmpty
        ? 'animation'
        : widget.page.pageAnimationListForTemplate.first;
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.shade100,
            border: Border.all(color: Colors.amber.shade700, width: 2),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.auto_awesome, size: 54),
        ),
        const SizedBox(height: 12),
        Text(
          animationName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Great job!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
