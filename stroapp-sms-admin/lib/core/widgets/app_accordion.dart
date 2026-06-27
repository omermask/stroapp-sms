import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ──────────────────────────────────────────────
// Accordion – Expandable item
// Used: Help Center FAQ
// ──────────────────────────────────────────────
class AppAccordion extends StatefulWidget {
  final String title;
  final String body;
  final bool initiallyExpanded;

  const AppAccordion({
    super.key,
    required this.title,
    required this.body,
    this.initiallyExpanded = false,
  });

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.accordionTitle.copyWith(
                        color: AppColors.cyprus,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      QasehIcons.arrowDownCurved,
                      color: AppColors.cyprus,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                widget.body,
                style: AppTypography.accordionBody.copyWith(
                  color: AppColors.cyprus,
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
