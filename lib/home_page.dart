//Please indicate your changes below. After reporting the changes, don't forget to write your name next to it -- MR-Ruhid
//You can place your own mod file links here.
//Do not touch the mod download link which is ruhidjavadov.site!
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'game_locator_dialog.dart';

class InstallerHomePage extends StatefulWidget {
  const InstallerHomePage({Key? key}) : super(key: key);

  @override
  State<InstallerHomePage> createState() => _InstallerHomePageState();
}

class _InstallerHomePageState extends State<InstallerHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  // --- PROQRAMIN MÖVCUD VERSİYASI ---
  final String currentAppVersion = "1.0";
  final String versionCheckUrl = "https://ruhidjavadov.site/app/dmod/version.json";

  Timer? _updateTimer;
  bool _isUpdateDialogShowing = false;

  final List<Map<String, dynamic>> _allPackages = [
    {
      "id": "lang",
      "title": "Azərbaycan Dili",
      "description": "Oyunu tamamilə doğma dilimizdə oynayın. Bütün interfeys tərcümə edilib.",
      "image": "assets/images/d1.png",
      "selected": true,
      "url": "https://ruhidjavadov.site/yuklemeler/data-localizations.pak",
      "fileName": "data-localizations.pak"
    },
    {
      "id": "mod",
      "title": "Milli Mod Paketi",
      "description": "Milli musiqilər və özəl loqolar. Oyuna fərqli bir ab-hava qatır.",
      "image": "assets/images/d2.png",
      "selected": true,
      "url": "https://ruhidjavadov.site/yuklemeler/data-windows.pak",
      "fileName": "data-windows.pak"
    },
  ];

  List<Map<String, dynamic>> _filteredPackages = [];
  bool _showWarning = true;

  bool _isDownloading = false;
  double? _progress = 0.0;
  String _downloadMessage = '';

  String? _installedGamePath;

  int _dotCount = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _filteredPackages = List.from(_allPackages);
    _searchController.addListener(_filterPackages);

    // Proqram açılanda ilk olaraq Kofe (Dəstək) dialoqunu göstər
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSupportDialog();
    });

    // İlk yoxlama
    _checkForUpdates();

    // Hər 1 dəqiqədən bir yenilənməni arxa planda yoxla
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_isUpdateDialogShowing) return;

    try {
      Response response = await _dio.get(versionCheckUrl);
      if (response.statusCode == 200) {
        var data = response.data;
        String serverVersion = data['version'].toString();
        String updateUrl = data['url'];
        String updateMessage = data['message'];

        if (serverVersion != currentAppVersion && !_isUpdateDialogShowing) {
          _showUpdateDialog(serverVersion, updateUrl, updateMessage);
        }
      }
    } catch (e) {
      debugPrint("Yenilənmə yoxlanarkən xəta: $e");
    }
  }

  void _showUpdateDialog(String newVersion, String url, String message) {
    _isUpdateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update_alt_rounded, color: Colors.greenAccent, size: 60),
              const SizedBox(height: 20),
              const Text(
                'YENİ VERSİYA MÖVCUDDUR!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('v$newVersion', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _isUpdateDialogShowing = false;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: const Text('SONRA'),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      _openUrl(url);
                      _isUpdateDialogShowing = false;
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('YENİLƏ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SupportDialog(onOpenUrl: _openUrl),
    );
  }

  void _filterPackages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPackages = _allPackages.where((pkg) {
        return pkg['title'].toString().toLowerCase().contains(query) ||
            pkg['description'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  int get _selectedCount {
    return _allPackages.where((pkg) => pkg['selected'] == true).length;
  }

  void _closeApp() {
    exit(0);
  }

  Future<void> _minimizeApp() async {
    await windowManager.minimize();
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchGame() async {
    if (_installedGamePath != null) {
      String exePath = "$_installedGamePath\\DYSMANTLE.exe";
      if (await File(exePath).exists()) {
        try {
          await Process.start(exePath, [], workingDirectory: _installedGamePath);
          _closeApp();
        } catch (e) {
          setState(() => _downloadMessage = "Xəta: Oyunu başlatmaq mümkün olmadı.");
        }
      }
    }
  }

  void _startDotAnimation() {
    _dotCount = 0;
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  void _stopDotAnimation() {
    _dotTimer?.cancel();
    setState(() => _dotCount = 0);
  }

  void _cancelDownload() {
    if (_cancelToken != null) {
      _cancelToken!.cancel("İstifadəçi tərəfindən dayandırıldı.");
      setState(() {
        _isDownloading = false;
        _downloadMessage = "Yükləmə dayandırıldı!";
        _progress = 0.0;
      });
      _stopDotAnimation();
    }
  }

  Future<void> _startInstallationProcess() async {
    String targetFolder = r"C:\Program Files (x86)\Steam\steamapps\common\DYSMANTLE";
    Directory dir = Directory(targetFolder);

    if (!await dir.exists()) {
      String? userSelectedPath = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const GameLocatorDialog(),
      );

      if (userSelectedPath != null && userSelectedPath.isNotEmpty) {
        targetFolder = userSelectedPath;
      } else {
        return;
      }
    }

    _installedGamePath = targetFolder;
    await _startDownloading(targetFolder);
  }

  Future<void> _startDownloading(String targetFolder) async {
    List<Map<String, dynamic>> packagesToInstall = _allPackages.where((pkg) => pkg['selected'] == true).toList();

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    _startDotAnimation();
    _cancelToken = CancelToken();

    try {
      for (int i = 0; i < packagesToInstall.length; i++) {
        String url = packagesToInstall[i]['url'];
        String fileName = packagesToInstall[i]['fileName'];
        String packageName = packagesToInstall[i]['title'];
        String savePath = "$targetFolder\\$fileName";

        setState(() => _downloadMessage = "$packageName: Nüsxə çıxarılır (Gözləyin)...");

        File originalFile = File(savePath);
        if (await originalFile.exists()) {
          String backupPath = "$targetFolder\\${fileName.replaceAll('.pak', '_backup.pak')}";
          if (await File(backupPath).exists()) await File(backupPath).delete();
          await originalFile.copy(backupPath);
        }

        String tempSavePath = "$savePath.tmp";
        setState(() => _downloadMessage = "$packageName: Serverə qoşulur...");

        await _dio.download(
          url, tempSavePath, cancelToken: _cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _progress = received / total;
                _downloadMessage = "$packageName: ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB";
              });
            } else {
              setState(() {
                _progress = null;
                _downloadMessage = "$packageName: ${(received / 1024 / 1024).toStringAsFixed(1)} MB çəkildi...";
              });
            }
          },
        );

        setState(() => _downloadMessage = "$packageName: Fayl yerləşdirilir...");
        File tempFile = File(tempSavePath);
        if (await originalFile.exists()) await originalFile.delete();
        await tempFile.rename(savePath);
      }

      setState(() {
        _isDownloading = false;
        _progress = 1.0;
        _downloadMessage = "Bütün fayllar uğurla quraşdırıldı!";
      });
      _stopDotAnimation();

    } catch (e) {
      if (!CancelToken.isCancel(e as DioException)) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = "Xəta baş verdi! İnterneti yoxlayın.";
          _progress = 0.0;
        });
        _stopDotAnimation();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dotTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String dots = "." * _dotCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Column(
        children: [
          // YUXARI BANNER
          ClipPath(
            clipper: HeaderWaveClipper(),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home_bg.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1A24)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.95)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 70, left: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE412A5).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('MİLLİ MODİFİKASİYA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Dysmantle Yükləmə Mərkəzi',
                          style: TextStyle(color: Colors.white, fontSize: screenWidth < 600 ? 28 : 42, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 70, right: 40,
                    child: screenWidth > 700 ? Row(
                      children: [
                        SocialIconBtn(icon: Icons.forum_rounded, tooltip: 'Discord', color: const Color(0xFF5865F2), url: 'https://discord.gg/2DZvzyVds', onTap: _openUrl),
                        const SizedBox(width: 10),
                        SocialIconBtn(icon: Icons.sports_esports_rounded, tooltip: 'Steam Topluluğu', color: const Color(0xFF1b2838), url: 'https://steamcommunity.com/groups/azegc', onTap: _openUrl),
                        const SizedBox(width: 10),
                        SocialIconBtn(icon: Icons.store_rounded, tooltip: 'Oyunu Al (Steam)', color: const Color(0xFF66c0f4), url: 'https://store.steampowered.com/app/846770/DYSMANTLE/', onTap: _openUrl),
                        const SizedBox(width: 10),
                        SocialIconBtn(icon: Icons.local_cafe_rounded, tooltip: 'Dəstək Ol (Kofe.al)', color: const Color(0xFFFF8C00), url: 'https://kofe.al/tr/@ruhidjavadoff', onTap: _openUrl),
                        const SizedBox(width: 10),
                        SocialIconBtn(icon: Icons.language_rounded, tooltip: 'Saytımız', color: const Color(0xFFE412A5), url: 'https://ruhidjavadov.site', onTap: _openUrl),
                        const SizedBox(width: 10),
                        SocialIconBtn(icon: Icons.code_rounded, tooltip: 'GitHub', color: Colors.grey.shade700, url: 'https://github.com/mr-ruhid', onTap: _openUrl),
                      ],
                    ) : const SizedBox(),
                  ),

                  Positioned(
                    top: 20, right: 20,
                    child: Row(
                      children: [
                        Material(color: Colors.black.withOpacity(0.4), shape: const CircleBorder(), clipBehavior: Clip.hardEdge, child: IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 28), onPressed: _minimizeApp, hoverColor: Colors.white.withOpacity(0.2))),
                        const SizedBox(width: 12),
                        Material(color: Colors.black.withOpacity(0.4), shape: const CircleBorder(), clipBehavior: Clip.hardEdge, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: _closeApp, hoverColor: Colors.red.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showWarning)
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), border: Border(left: BorderSide(color: Colors.amber.shade600, width: 4)), borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.amber.shade600, size: 28), const SizedBox(width: 15),
                          const Expanded(child: Text('Diqqət: Quraşdırma zamanı xəta almamaq üçün oyunun arxa planda tam bağlı olduğundan əmin olun!', style: TextStyle(color: Colors.white70, fontSize: 15))),
                          IconButton(icon: Icon(Icons.close, color: Colors.amber.shade600), onPressed: () => setState(() => _showWarning = false))
                        ],
                      ),
                    ),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 20, runSpacing: 15,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Paketlər və Əlavələr', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF9D28F0).withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('Seçili: $_selectedCount', style: const TextStyle(color: Color(0xFFD080FF), fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        width: 250, height: 45,
                        child: TextField(
                          controller: _searchController, style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(hintText: 'Paket axtar...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), prefixIcon: const Icon(Icons.search, color: Colors.white54), filled: true, fillColor: const Color(0xFF1E1E28), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _filteredPackages.isEmpty
                      ? const Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text('Uyğun paket tapılmadı.', style: TextStyle(color: Colors.white54, fontSize: 16))))
                      : GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: screenWidth < 700 ? 400 : 250, crossAxisSpacing: 25, mainAxisSpacing: 25, childAspectRatio: 0.8),
                    itemCount: _filteredPackages.length,
                    itemBuilder: (context, index) {
                      final pkg = _filteredPackages[index];
                      return PackageCardItem(
                        pkg: pkg,
                        onChanged: (bool? value) {
                          if (_isDownloading) return;
                          setState(() {
                            int realIndex = _allPackages.indexWhere((p) => p['id'] == pkg['id']);
                            _allPackages[realIndex]['selected'] = value ?? false;
                            pkg['selected'] = value ?? false;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Container(
            height: 90, width: double.infinity, padding: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 20 : 40),
            decoration: BoxDecoration(color: const Color(0xFF15151D), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _isDownloading
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_downloadMessage, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: Row(
                          children: [
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _progress, backgroundColor: const Color(0xFF2A2A35), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE412A5)), minHeight: 6))),
                            const SizedBox(width: 15),
                            Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: _cancelDownload, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 1.5)), child: const Icon(Icons.close_rounded, color: Colors.red, size: 20)))),
                          ],
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_downloadMessage.isNotEmpty ? _downloadMessage : (_selectedCount > 0 ? 'Quraşdırmağa hazırdır' : 'Paket seçilməyib'), style: TextStyle(color: _downloadMessage.contains('Uğurla') ? Colors.greenAccent : _downloadMessage.contains('dayandırıldı') ? Colors.redAccent : Colors.white.withOpacity(0.5), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$_selectedCount paket seçildi', style: TextStyle(color: Colors.white, fontSize: screenWidth < 600 ? 14 : 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: _progress == 1.0
                      ? _launchGame
                      : ((_selectedCount > 0 && !_isDownloading) ? _startInstallationProcess : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _progress == 1.0 ? Colors.greenAccent.shade700 : const Color(0xFF9D28F0),
                    disabledBackgroundColor: const Color(0xFF2A2A35),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white30,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: (_selectedCount > 0 && !_isDownloading) ? 10 : 0,
                    shadowColor: _progress == 1.0 ? Colors.greenAccent.withOpacity(0.5) : const Color(0xFF9D28F0).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDownloading) ...[
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                      ] else ...[
                        Icon(_progress == 1.0 ? Icons.play_arrow_rounded : Icons.download_rounded, size: screenWidth < 600 ? 20 : 28),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 150,
                        child: Text(
                          _isDownloading ? 'YÜKLƏNİR$dots' : (_progress == 1.0 ? 'OYUNU BAŞLAT' : 'SEÇİLƏNLƏRİ YÜKLƏ'),
                          style: TextStyle(fontSize: screenWidth < 600 ? 14 : 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocialIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final String url;
  final Function(String) onTap;

  const SocialIconBtn({Key? key, required this.icon, required this.tooltip, required this.color, required this.url, required this.onTap}) : super(key: key);

  @override
  State<SocialIconBtn> createState() => _SocialIconBtnState();
}

class _SocialIconBtnState extends State<SocialIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.url),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withOpacity(0.8) : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: _hovered ? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : [],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class SupportDialog extends StatefulWidget {
  final Function(String) onOpenUrl;
  const SupportDialog({Key? key, required this.onOpenUrl}) : super(key: key);

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  int _timeLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          border: Border.all(color: Colors.orangeAccent, width: 2),
          boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_cafe_rounded, color: Colors.orangeAccent, size: 60),
            const SizedBox(height: 20),
            const Text(
              'BİZƏ DƏSTƏK OLUN',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'Bu milli modifikasiya layihəsi tamamilə pulsuzdur.\nƏgər əməyimizi qiymətləndirib bizə bir kofe almaq istəsəniz, çox şad olarıq!',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: OutlinedButton(
                    onPressed: _timeLeft == 0 ? () => Navigator.pop(context) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white30,
                      side: BorderSide(color: _timeLeft == 0 ? Colors.white30 : Colors.transparent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    child: Text(_timeLeft > 0 ? 'Gözləyin ($_timeLeft)' : 'BAĞLA'),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onOpenUrl('https://kofe.al/tr/@ruhidjavadoff');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('KOFE AL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PackageCardItem extends StatefulWidget {
  final Map<String, dynamic> pkg;
  final ValueChanged<bool?> onChanged;

  const PackageCardItem({Key? key, required this.pkg, required this.onChanged}) : super(key: key);

  @override
  State<PackageCardItem> createState() => _PackageCardItemState();
}

class _PackageCardItemState extends State<PackageCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.pkg['selected'];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFE412A5) : Colors.transparent, width: 2),
          boxShadow: _isHovered
              ? [BoxShadow(color: const Color(0xFFE412A5).withOpacity(0.3), blurRadius: 15, spreadRadius: 1)]
              : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.pkg['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1E1E28),
                  child: const Center(child: Icon(Icons.image, size: 40, color: Colors.white24)),
                ),
              ),
              AnimatedOpacity(
                opacity: _isHovered ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.pkg['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.pkg['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.pkg['description'],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8, left: 8,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                  child: Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFE412A5),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
