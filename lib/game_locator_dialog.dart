//Here you can specify where your chosen mod will upload files, but remember that the current file finder system must remain fixed; you can only add new files to it!
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:collection';
import 'package:file_picker/file_picker.dart';

class GameLocatorDialog extends StatefulWidget {
  const GameLocatorDialog({Key? key}) : super(key: key);

  @override
  State<GameLocatorDialog> createState() => _GameLocatorDialogState();
}

class _GameLocatorDialogState extends State<GameLocatorDialog> {
  bool _isSearching = false;
  String _searchStatus = '';

  // MANUAL SEÇİM MƏNTİQİ
  Future<void> _manualSearch() async {
    String? selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'DYSMANTLE.exe olan qovluğu seçin',
    );

    if (selectedPath != null && selectedPath.isNotEmpty) {
      // Seçilən qovluqda DYSMANTLE.exe olub-olmadığını yoxlayırıq
      File exeFile = File("$selectedPath\\DYSMANTLE.exe");
      if (await exeFile.exists()) {
        if (mounted) Navigator.pop(context, selectedPath);
      } else {
        setState(() {
          _searchStatus = "Xəta: Seçilən qovluqda DYSMANTLE.exe tapılmadı!";
        });
      }
    }
  }

  // AVTOMATİK AXTARIŞ MƏNTİQİ
  Future<void> _autoSearch() async {
    setState(() {
      _isSearching = true;
      _searchStatus = "Disklər yoxlanılır. Zəhmət olmasa gözləyin...";
    });

    // Ən çox oyun quraşdırılan standart qovluqlar (Sürətli tapmaq üçün)
    List<String> commonPaths = [
      r'C:\Program Files (x86)\Steam\steamapps\common',
      r'C:\Program Files\Steam\steamapps\common',
      r'D:\SteamLibrary\steamapps\common',
      r'E:\SteamLibrary\steamapps\common',
      r'C:\Games',
      r'D:\Games',
      r'E:\Games',
      r'C:\GOG Games',
      r'D:\GOG Games',
    ];

    String? foundPath;

    // 1. Öncə ən çox ehtimal olunan qovluqları yoxlayırıq
    for (String basePath in commonPaths) {
      if (foundPath != null) break;
      Directory baseDir = Directory(basePath);
      if (await baseDir.exists()) {
        foundPath = await _searchInDirectorySafe(baseDir);
      }
    }

    // 2. Əgər standart yerlərdə yoxdursa, bütün əsas diskləri (C, D, E) ümumi yoxlayırıq
    if (foundPath == null) {
      List<String> drives = ['C:\\', 'D:\\', 'E:\\'];
      for (String drive in drives) {
        if (foundPath != null) break;
        Directory driveDir = Directory(drive);
        if (await driveDir.exists()) {
          foundPath = await _searchInDirectorySafe(driveDir, maxDepth: 4); // Çox dərinə getmirik ki, PC donmasın
        }
      }
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
      });

      if (foundPath != null) {
        // Tapıldısa avtomatik olaraq yolu qaytarırıq
        Navigator.pop(context, foundPath);
      } else {
        setState(() {
          _searchStatus = "Avtomatik axtarış nəticə vermədi. Lütfən manual seçin.";
        });
      }
    }
  }

  // TƏHLÜKƏSİZ QOVLUQ AXTARIŞ ALQORİTMİ (Sistem xətalarından qaçmaq üçün)
  Future<String?> _searchInDirectorySafe(Directory startDir, {int maxDepth = 3}) async {
    Queue<Map<String, dynamic>> queue = Queue();
    queue.add({'dir': startDir, 'depth': 0});

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      Directory currentDir = current['dir'];
      int currentDepth = current['depth'];

      if (currentDepth > maxDepth) continue;

      if (mounted) {
        setState(() => _searchStatus = "Axtarılır: ${currentDir.path}");
      }

      // UI donmasın deyə kiçik bir fasilə veririk
      await Future.delayed(const Duration(milliseconds: 1));

      try {
        List<FileSystemEntity> entities = currentDir.listSync(followLinks: false);
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('DYSMANTLE.exe')) {
            return currentDir.path; // Oyunu tapdıq!
          } else if (entity is Directory) {
            // Windows-un qorunan qovluqlarına girmirik
            if (!entity.path.contains('Windows') && !entity.path.contains('System Volume Information')) {
              queue.add({'dir': entity, 'depth': currentDepth + 1});
            }
          }
        }
      } catch (e) {
        // "Access Denied" (İcazə yoxdur) xətalarını iqnor edib davam edirik
        continue;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE412A5), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFE412A5).withOpacity(0.3), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore_rounded, color: Colors.amber, size: 60),
            const SizedBox(height: 20),
            const Text(
              'OYUN QOVLUĞU TAPILMADI',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'Dysmantle oyunu standart qovluqda tapılmadı.\nZəhmət olmasa içində "DYSMANTLE.exe" olan qovluğu göstərin.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // STATUS MƏTNI
            if (_searchStatus.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _searchStatus,
                  style: TextStyle(
                    color: _searchStatus.contains('Xəta') || _searchStatus.contains('nəticə vermədi')
                        ? Colors.redAccent
                        : Colors.amber,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // DÜYMƏLƏR
            if (_isSearching)
              const CircularProgressIndicator(color: Color(0xFFE412A5))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _manualSearch,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('MANUAL SEÇ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _autoSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('AVTO AXTARIŞ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9D28F0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            if (!_isSearching)
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('LƏĞV ET', style: TextStyle(color: Colors.white54)),
              )
          ],
        ),
      ),
    );
  }
}
