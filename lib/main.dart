import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/editor_provider.dart';
import 'providers/file_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // システム設定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // データベース初期化
  await DatabaseService.instance.initialize();
  
  runApp(const RawPhotoEditorApp());
}

class RawPhotoEditorApp extends StatelessWidget {
  const RawPhotoEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => FileProvider()),
        ChangeNotifierProvider(create: (context) => EditorProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'RAW Photo Editor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'RobotoMono',
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}