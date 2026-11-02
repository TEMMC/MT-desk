import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/platform_bridge.dart';
import '../theme/droid_theme.dart';

class DesktopAppearanceScreen extends StatefulWidget {
  const DesktopAppearanceScreen({super.key});
  @override
  State<DesktopAppearanceScreen> createState() => _DesktopAppearanceScreenState();
}

class _DesktopAppearanceScreenState extends State<DesktopAppearanceScreen> {
  static const _wallpapers = <(String, String)>[
    ('Neon Core', 'assets/wallpapers/neon-core.svg'),
    ('Digital Rain', 'assets/wallpapers/digital-rain.svg'),
    ('Cyber Grid', 'assets/wallpapers/cyber-grid.svg'),
    ('Circuit Breaker', 'assets/wallpapers/circuit-breaker.svg'),
    ('Global Network', 'assets/wallpapers/global-network.svg'),
  ];
  static const _resolutions = <(String, int, int)>[
    ('HD · 1280 × 720', 1280, 720),
    ('HD+ · 1600 × 900', 1600, 900),
    ('Full HD · 1920 × 1080', 1920, 1080),
    ('QHD · 2560 × 1440', 2560, 1440),
    ('Auto / Default', 0, 0),
  ];
  int _iconSize = 48;
  int _wallpaper = 0;
  String _resolution = 'Auto / Default';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _iconSize = p.getInt('desktopIconSize') ?? 48;
      _wallpaper = (p.getInt('desktopWallpaper') ?? 0).clamp(0, 4);
      _resolution = p.getString('desktopResolution') ?? 'Auto / Default';
    });
  }

  Future<void> _run(String command, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final output = await DroidDeskPlatform.executeCommand(command);
      if (!mounted) return;
      final ok = !output.toLowerCase().contains('cannot') &&
          !output.toLowerCase().contains('not found') &&
          !output.toLowerCase().contains('failed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? success : 'Could not apply setting: $output'),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Desktop command failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setResolution((String, int, int) value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('desktopResolution', value.$1);
    setState(() => _resolution = value.$1);
    final command = value.$2 == 0
        ? 'xrandr --auto 2>/dev/null || true'
        : 'xrandr --fb ${value.$2}x${value.$3} 2>&1';
    await _run(command, 'Resolution request sent: ${value.$1}');
  }

  Future<void> _setIconSize(double value) async {
    final size = value.round();
    setState(() => _iconSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('desktopIconSize', size);
    await _run(
      'xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size --create -t int -s $size 2>&1',
      'Desktop icon size set to $size px',
    );
  }

  Future<void> _setWallpaper(int index) async {
    setState(() => _wallpaper = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('desktopWallpaper', index);
    final data = await rootBundle.load(_wallpapers[index].$2);
    final encoded = base64Encode(data.buffer.asUint8List());
    final path = '/tmp/mt-desk-wallpaper-${index + 1}.svg';
    final command = "printf '%s' '$encoded' | base64 -d > '$path' && "
        "xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image "
        "--create -t string -s '$path' 2>&1";
    await _run(command, 'Wallpaper applied: ${_wallpapers[index].$1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DroidTheme.background,
      appBar: AppBar(
        title: const Text('Desktop Appearance'),
        backgroundColor: DroidTheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _section('DISPLAY RESOLUTION', Icons.monitor_rounded),
          _card(Column(children: [
            for (final item in _resolutions)
              RadioListTile<String>(
                value: item.$1,
                groupValue: _resolution,
                activeColor: DroidTheme.primary,
                title: Text(item.$1),
                onChanged: _busy ? null : (_) => _setResolution(item),
              ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Resolution is applied to the active X11 desktop session. Some display backends may expose only supported modes.'),
            ),
          ])),
          const SizedBox(height: 22),
          _section('DESKTOP ICON SIZE', Icons.apps_rounded),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_iconSize px', style: DroidTheme.headingMd),
            Slider(
              value: _iconSize.toDouble(),
              min: 24, max: 96, divisions: 12,
              activeColor: DroidTheme.primary,
              label: '$_iconSize px',
              onChanged: _busy ? null : (v) => setState(() => _iconSize = v.round()),
              onChangeEnd: _busy ? null : _setIconSize,
            ),
            const Text('Adjusts XFCE desktop icon size.'),
          ])),
          const SizedBox(height: 22),
          _section('HACKER WALLPAPERS · 5 THEMES', Icons.wallpaper_rounded),
          for (var i = 0; i < _wallpapers.length; i++) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _busy ? null : () => _setWallpaper(i),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DroidTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _wallpaper == i ? DroidTheme.primary : DroidTheme.surfaceBorder,
                    width: _wallpaper == i ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 116, height: 66,
                      child: SvgPicture.asset(_wallpapers[i].$2, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(_wallpapers[i].$1, style: DroidTheme.headingSm)),
                  if (_wallpaper == i) Icon(Icons.check_circle, color: DroidTheme.primary),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : () => _setWallpaper(_wallpaper),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: Text(_busy ? 'Applying…' : 'Apply selected wallpaper'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: DroidTheme.primary),
      const SizedBox(width: 9),
      Text(title, style: DroidTheme.label.copyWith(color: DroidTheme.primary)),
    ]),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DroidTheme.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DroidTheme.surfaceBorder),
    ),
    child: child,
  );
}
