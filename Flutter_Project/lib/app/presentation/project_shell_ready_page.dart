import 'package:flutter/material.dart';

class ProjectShellReadyPage extends StatelessWidget {
  const ProjectShellReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Blocker'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Project shell ready',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Step 01 translated the legacy launch shell into a Flutter bootstrap '
              'layer only. Real routes, feature controllers, persistence, and '
              'platform adapters stay deferred so later steps can migrate them '
              'cleanly from the native sources.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const _ShellCard(
              icon: Icons.alt_route_rounded,
              title: 'Legacy shell mapping',
              body:
                  'The old Android entry Activities are now represented as planned '
                  'Flutter pages inside the new shared shell.',
              child: Column(
                children: [
                  _MappingRow(
                    source: 'MainActivity',
                    target: 'planned /home Flutter entry',
                  ),
                  SizedBox(height: 12),
                  _MappingRow(
                    source: 'UsageActivity',
                    target: 'planned /usage Flutter page',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _ShellCard(
              icon: Icons.developer_mode_rounded,
              title: 'Bootstrap boundary',
              body:
                  'This shell intentionally stops before feature logic. The app '
                  'root now owns only Flutter startup, theme wiring, ProviderScope, '
                  'and a temporary placeholder screen.',
            ),
            const SizedBox(height: 16),
            const _ShellCard(
              icon: Icons.info_outline_rounded,
              title: 'Environment note',
              body:
                  'Flutter SDK is not installed in this workspace, so android/ and '
                  'ios/ still need to be generated later with '
                  '`flutter create . --platforms=android,ios` once the toolchain is '
                  'available.',
            ),
            const SizedBox(height: 16),
            const _ShellCard(
              icon: Icons.next_plan_rounded,
              title: 'Next unlocked work',
              body:
                  'Step 02 can now focus only on typed failures, shared constants, '
                  'immutable domain baselines, and tests without revisiting the app '
                  'shell.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellCard extends StatelessWidget {
  const _ShellCard({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({
    required this.source,
    required this.target,
  });

  final String source;
  final String target;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$source ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: '-> '),
            TextSpan(
              text: target,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
