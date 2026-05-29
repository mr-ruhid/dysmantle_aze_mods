import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'loading_page.dart'; // İlk açılacaq səhifəni çağırırıq

void main() async {
  // Flutter vidjetlərini və window_manager paketini inisializasiya edirik
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Pəncərənin xüsusiyyətlərini (elastiklik və görünüş) təyin edirik
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720), // Standart ilkin ölçü
    minimumSize: Size(800, 600), // YENİ: Ekran həddindən artıq kiçiləndə dizayn sınmasın deyə minimum limit
    center: true, // Ekranda mərkəzə yerləşdir
    backgroundColor: Colors.transparent, // Arxa fonu şəffaf edirik ki, öz dizaynımız görünsün
    skipTaskbar: false, // Aşağıdakı paneldə (taskbar-da) proqramın ikonunu göstər
    titleBarStyle: TitleBarStyle.hidden, // Yuxarıdakı standart Windows panelini gizlədirik
  );

  // Pəncərə tam hazır olana qədər gözləyirik və ekrana göstəririk
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Pəncərəni göstər
    await windowManager.maximize(); // Ekrana tam otursun (Full Screen yox, Maximized olur ki kiçiltmək mümkün olsun)
    await windowManager.focus(); // Fikri proqrama yönəlt
  });

  // Tətbiqi işə salırıq
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dysmantle Milli Mod Quraşdırıcı',
      debugShowCheckedModeBanner: false, // Sağ yuxarıdakı "DEBUG" yazısını yığışdırırıq
      theme: ThemeData(
        // Qaranlıq və neon bənövşəyi temamız
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D28F0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoadingPage(), // Proqram açılanda ilk olaraq yükləmə səhifəsinə gedir
    );
  }
}