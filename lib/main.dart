import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: EduOpsApp()));
}

class EduOpsApp extends ConsumerWidget {
  const EduOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EduOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter(ref),
    );
  }
}
