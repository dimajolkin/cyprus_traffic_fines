import 'package:flutter/material.dart';
import '../services/translator.dart';
import '../services/cy_camera_system/cy_camera_service.dart';
import 'database_viewer.dart';

class SettingsScreen extends StatefulWidget {
  final Translator translator;

  SettingsScreen({Key? key, required this.translator}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _debugModeEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadDebugMode();
  }
  
  /// Загружает состояние режима отладки из настроек
  Future<void> _loadDebugMode() async {
    final isDebugMode = await CyCameraService.debugMode;
    setState(() {
      _debugModeEnabled = isDebugMode;
    });
  }
  
  /// Сохраняет состояние режима отладки в настройки
  Future<void> _saveDebugMode(bool value) async {
    await CyCameraService.setDebugMode(value);
    setState(() {
      _debugModeEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.translator.get('settings')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.translator.get('app_settings'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(widget.translator.get('notifications')),
                    subtitle: Text(widget.translator.get('notifications_description')),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  Divider(),
                  SwitchListTile(
                    title: Text(widget.translator.get('dark_mode')),
                    subtitle: Text(widget.translator.get('dark_mode_description')),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              widget.translator.get('about_app'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.translator.get('app_version'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('1.0.0'),
                    SizedBox(height: 8),
                    Text(
                      widget.translator.get('app_description'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Отладка",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text("Режим отладки WebView"),
                    subtitle: Text("Показывать WebView при поиске штрафов"),
                    value: _debugModeEnabled,
                    secondary: Icon(Icons.bug_report),
                    onChanged: (value) {
                      _saveDebugMode(value);
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.storage),
                    title: Text("Просмотр базы данных"),
                    subtitle: Text("Просмотр содержимого базы данных приложения"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DatabaseViewerScreen(translator: widget.translator),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 