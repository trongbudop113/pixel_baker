import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/story_models.dart';
import '../../app/routing/app_router.dart';
import 'story_state.dart';

class StoryColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

class ResponsiveStoryScreen extends StatefulWidget {
  const ResponsiveStoryScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveStoryScreen> createState() => _ResponsiveStoryScreenState();
}

class _ResponsiveStoryScreenState extends State<ResponsiveStoryScreen> {
  final StoryState _state = StoryState();

  @override
  void initState() {
    super.initState();
    _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? StoryMobile(state: _state, showTopHeader: widget.showTopHeader)
            : StoryWeb(state: _state, showTopHeader: widget.showTopHeader);
      },
    );
  }
}

class StoryWeb extends StatelessWidget {
  const StoryWeb({super.key, required this.state, required this.showTopHeader});

  final StoryState state;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        if (state.isLoading) {
          return const _StoryLoadingSkeleton();
        }
        return SizedBox(
          width: 1200,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: StoryColors.gray, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTopHeader) _header(context, page.headerTitle),
                if (showTopHeader) const SizedBox(height: 14),
                if (state.errorMessage != null) ...[
                  _statusBanner(state.errorMessage!, false),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _hero(page),
                        const SizedBox(height: 14),
                        _timeline(page),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _values(page.values)),
                            const SizedBox(width: 14),
                            Expanded(child: _craft(page.craft)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _imageTimeline(page),
                        const SizedBox(height: 14),
                        _cta(context, page.cta),
                        const SizedBox(height: 14),
                        _footer(page.footerLabel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String headerTitle) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF4F8FF)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.home),
              child: _txt('PIXEL BAKERY', StoryColors.red, 18, FontWeight.w900),
            ),
            const Spacer(),
            _txt(headerTitle, StoryColors.blue, 14, FontWeight.w700),
          ],
        ),
      );

  Widget _hero(StoryPageResponse page) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _txt(page.heroTitle, StoryColors.blue, 30, FontWeight.w900),
                  const SizedBox(height: 8),
                  _txt(
                    page.heroDescription,
                    StoryColors.gray,
                    14,
                    FontWeight.w500,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 168,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StoryColors.gray, width: 2),
                ),
                alignment: Alignment.center,
                child: _txt(page.heroBadge, StoryColors.red, 22, FontWeight.w800),
              ),
            ),
          ],
        ),
      );

  Widget _timeline(StoryPageResponse page) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.timelineTitle, StoryColors.blue, 20, FontWeight.w800),
            const SizedBox(height: 10),
            for (var index = 0; index < page.timelineItems.length; index++) ...[
              _step(page.timelineItems[index]),
              if (index != page.timelineItems.length - 1)
                const SizedBox(height: 8),
            ],
          ],
        ),
      );

  Widget _values(StorySectionModel values) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(values.title, StoryColors.blue, 18, FontWeight.w800),
            const SizedBox(height: 10),
            for (final item in values.items) _bullet(item),
          ],
        ),
      );

  Widget _imageTimeline(StoryPageResponse page) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.imageTimelineTitle, StoryColors.blue, 18, FontWeight.w800),
            const SizedBox(height: 12),
            SizedBox(
              height: 232,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < page.imageTimelineItems.length; index++) ...[
                    Expanded(
                      child: _imageTimelineCard(
                        item: page.imageTimelineItems[index],
                        isLast: index == page.imageTimelineItems.length - 1,
                      ),
                    ),
                    if (index != page.imageTimelineItems.length - 1)
                      const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _craft(StoryCraftSectionModel craft) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(craft.title, StoryColors.blue, 18, FontWeight.w800),
            const SizedBox(height: 10),
            _txt(craft.description, StoryColors.gray, 13, FontWeight.w500),
            const SizedBox(height: 12),
            Container(
              height: 108,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StoryColors.gray, width: 2),
              ),
              alignment: Alignment.center,
              child: _txt(craft.previewLabel, StoryColors.gray, 14, FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _imageTimelineCard({
    required StoryImageTimelineItemModel item,
    required bool isLast,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StoryColors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _txt(item.year, Colors.white, 11, FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : StoryColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StoryColors.gray, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: StoryColors.gray, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: _txt(
                        item.previewLabel,
                        StoryColors.gray,
                        13,
                        FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _txt(item.title, StoryColors.blue, 14, FontWeight.w800),
                  const SizedBox(height: 6),
                  _txt(item.description, StoryColors.gray, 12, FontWeight.w500),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _cta(BuildContext context, StoryCtaSectionModel cta) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Row(
          children: [
            Expanded(
              child: _txt(
                cta.description,
                StoryColors.gray,
                14,
                FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.menu),
              child: Container(
                width: 180,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StoryColors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StoryColors.gray, width: 2),
                ),
                child: _txt(cta.buttonLabel, Colors.white, 13, FontWeight.w900),
              ),
            ),
          ],
        ),
      );

  Widget _footer(String footerLabel) => Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
        child: _txt(footerLabel, StoryColors.gray, 10, FontWeight.w700),
      );

  Widget _step(StoryTimelineItemModel item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StoryColors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: _txt(item.year, Colors.white, 12, FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _txt(item.description, StoryColors.gray, 13, FontWeight.w600),
          ),
        ],
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _txt('• $text', StoryColors.gray, 13, FontWeight.w600),
      );

  Widget _statusBanner(String message, bool isSuccess) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSuccess ? StoryColors.green : StoryColors.red,
            width: 2,
          ),
        ),
        child: _txt(
          message,
          isSuccess ? StoryColors.green : StoryColors.red,
          13,
          FontWeight.w700,
        ),
      );

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StoryColors.gray, width: 2),
      );

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'Noto Sans',
        ),
      );
}

class StoryMobile extends StatelessWidget {
  const StoryMobile({super.key, required this.state, required this.showTopHeader});

  final StoryState state;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final page = state.pageResponse;
        if (state.isLoading) {
          return const _StoryLoadingSkeleton(mobile: true);
        }
        return SizedBox(
          width: 390,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: StoryColors.gray, width: 3),
            ),
            child: Column(
              children: [
                if (showTopHeader) _mobileHeader(context, page.headerTitle),
                if (showTopHeader) const SizedBox(height: 10),
                if (state.errorMessage != null) ...[
                  _mobileStatusBanner(state.errorMessage!, false),
                  const SizedBox(height: 10),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _mobileHero(page),
                        const SizedBox(height: 10),
                        _mobileSection(
                          page.timelineTitle,
                          page.timelineItems
                              .map((item) => '${item.year}: ${item.description}')
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 10),
                        _mobileImageTimeline(page),
                        const SizedBox(height: 10),
                        _mobileSection(page.values.title, page.values.items),
                        const SizedBox(height: 10),
                        _mobileSection(
                          page.craft.title,
                          [page.craft.description, page.craft.previewLabel],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => context.goNamed(AppRouteNames.menu),
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: StoryColors.red,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: StoryColors.gray, width: 2),
                            ),
                            child: _txt(
                              page.cta.buttonLabel,
                              Colors.white,
                              13,
                              FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _mobileFooter(page.footerLabel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileHeader(BuildContext context, String headerTitle) => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.home),
              child: _txt('PIXEL BAKERY', StoryColors.red, 13, FontWeight.w900),
            ),
            const Spacer(),
            _txt(headerTitle, StoryColors.blue, 11, FontWeight.w700),
          ],
        ),
      );

  Widget _mobileImageTimeline(StoryPageResponse page) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _mBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.imageTimelineTitle, StoryColors.blue, 15, FontWeight.w800),
            const SizedBox(height: 8),
            for (var index = 0; index < page.imageTimelineItems.length; index++) ...[
              _mobileImageTimelineCard(page.imageTimelineItems[index]),
              if (index != page.imageTimelineItems.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
      );

  Widget _mobileImageTimelineCard(StoryImageTimelineItemModel item) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: StoryColors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _txt(item.year, Colors.white, 11, FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StoryColors.gray, width: 2),
              ),
              child: _txt(item.previewLabel, StoryColors.gray, 13, FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _txt(item.title, StoryColors.blue, 13, FontWeight.w800),
            const SizedBox(height: 4),
            _txt(item.description, StoryColors.gray, 12, FontWeight.w500),
          ],
        ),
      );

  Widget _mobileHero(StoryPageResponse page) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _mBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(page.heroTitle, StoryColors.blue, 20, FontWeight.w900),
            const SizedBox(height: 6),
            _txt(page.heroDescription, StoryColors.gray, 12, FontWeight.w500),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StoryColors.gray, width: 2),
              ),
              child: _txt(page.heroBadge, StoryColors.red, 16, FontWeight.w800),
            ),
          ],
        ),
      );

  Widget _mobileSection(String title, List<String> lines) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _mBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(title, StoryColors.blue, 15, FontWeight.w800),
            const SizedBox(height: 8),
            for (final line in lines) ...[
              _txt('• $line', StoryColors.gray, 12, FontWeight.w600),
              const SizedBox(height: 4),
            ],
          ],
        ),
      );

  Widget _mobileFooter(String footerLabel) => Container(
        width: double.infinity,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
        child: _txt(footerLabel, StoryColors.gray, 10, FontWeight.w700),
      );

  Widget _mobileStatusBanner(String message, bool isSuccess) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSuccess ? StoryColors.green : StoryColors.red,
            width: 2,
          ),
        ),
        child: _txt(
          message,
          isSuccess ? StoryColors.green : StoryColors.red,
          12,
          FontWeight.w700,
        ),
      );

  BoxDecoration _mBox() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StoryColors.gray, width: 2),
      );

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'Noto Sans',
        ),
      );
}

class _StoryLoadingSkeleton extends StatelessWidget {
  const _StoryLoadingSkeleton({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mobile ? 390 : 1200,
      height: double.infinity,
      padding: EdgeInsets.all(mobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: StoryColors.gray, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line(width: mobile ? 180 : 260, height: mobile ? 18 : 22),
          SizedBox(height: mobile ? 10 : 14),
          _block(height: mobile ? 180 : 220),
          SizedBox(height: mobile ? 10 : 14),
          _block(height: mobile ? 220 : 180),
          SizedBox(height: mobile ? 10 : 14),
          if (mobile) ...[
            _block(height: 150),
            const SizedBox(height: 10),
            _block(height: 150),
          ] else
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _block(height: 180)),
                  const SizedBox(width: 14),
                  Expanded(child: _block(height: 180)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _block({required double height}) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: StoryColors.gray, width: 2),
        ),
      );

  Widget _line({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EAF2),
          borderRadius: BorderRadius.circular(999),
        ),
      );
}
