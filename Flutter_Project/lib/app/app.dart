import 'package:flutter/material.dart';

import 'presentation/project_shell_ready_page.dart';
import 'theme/app_theme.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Subtitle Blocker',
      theme: AppTheme.light(),
      home: const ProjectShellReadyPage(),
    );
  }
}
