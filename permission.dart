import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // 폰의 종류(안드로이드 등)를 알기 위해 필요해요
import 'package:device_info_plus/device_info_plus.dart'; // 폰 버전(14인지 등)을 알기 위해 필요해요
import 'package:flutter/services.dart'; // 무전기(MethodChannel)를 쓰기 위해 필요해요
import '../services/translation_service.dart';

class PermissionGuidePage extends StatelessWidget {
  final VoidCallback onAllDone; // 권한 작업 다 끝나면 메인으로 보내줄 콜백

  // 📻 메인에 있는 무전기랑 주파수를 맞춥니다 (전체화면 권한용)
  static const platform = MethodChannel('com.coinguardian.app/emergency');

  const PermissionGuidePage({super.key, required this.onAllDone});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // 🕵️ 지금 이 폰이 안드로이드 14 이상인지 확인해봅니다.
        future: _isAndroid14OrHigher(),
        builder: (context, snapshot) {
          bool isAndroid14 = snapshot.data ?? false;

          return Scaffold(
            backgroundColor: const Color(0xFF0B0E11),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              S.isEn ? "App Access Permissions" : "앱 접근권한 안내",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              S.isEn
                                  ? "Please allow the following permissions\nfor stable alarm reception of Coin Guardian."
                                  : "코인수호신의 안정적인 알람 수신을 위해\n다음 권한들을 허용해 주시기 바랍니다.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF848E9C), fontSize: 14, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 48),
                          const Divider(color: Color(0xFF2B3139)),
                          const SizedBox(height: 24),

                          // 1. 알림 권한
                          _buildPermissionItem(
                            icon: Icons.notifications_active_outlined,
                            title: S.isEn ? "Notifications" : "알람 (필수)",
                            desc: S.isEn ? "Receive real-time crypto alerts." : "실시간 시세 및 지표 알람용",
                          ),

                          // 2. 배터리 최적화 제외
                          _buildPermissionItem(
                            icon: Icons.battery_saver_outlined,
                            title: S.isEn ? "Battery Exemption" : "배터리 최적화 제외 (필수)",
                            desc: S.isEn ? "Keep alerts working in background." : "백그라운드 알람 수신용",
                          ),

                          // 3. 다른 앱 위에 표시
                          _buildPermissionItem(
                            icon: Icons.layers_outlined,
                            title: S.isEn ? "Overlay Permission" : "다른 앱 위에 표시 (필수)",
                            desc: S.isEn ? "Show full-screen alerts instantly." : "잠금 화면 위 전체 화면 알람용",
                          ),

                          // 4. 안드로이드 14 이상
                          if (isAndroid14)
                            _buildPermissionItem(
                              icon: Icons.fullscreen_exit,
                              title: S.isEn ? "Full-Screen Alerts" : "전체 화면 알람 (필수)",
                              desc: S.isEn ? "Display alerts on lock screen." : "잠금 상태 알람 창 표시용",
                            ),

                          const SizedBox(height: 40),
                          Text(
                            S.isEn
                                ? "• You can change these anytime in Settings."
                                : "• 접근 권한은 설정 > 앱 > 코인수호신에서 언제든 변경 가능합니다.",
                            style: const TextStyle(color: Color(0xFF474D57), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 하단 확인 버튼
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFCD535),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _requestPermissionsSequence(context, isAndroid14),
                      child: Text(
                        S.isEn ? "Confirm" : "확인",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildPermissionItem({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E2329), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFFCD535), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🕵️ 안드로이드 14 이상인지 확인하는 도구
  Future<bool> _isAndroid14OrHigher() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.version.sdkInt >= 34;
    }
    return false;
  }

  // 🎯 권한 팝업을 하나씩 순차적으로 띄우는 함수 (연속 사격!)
  Future<void> _requestPermissionsSequence(BuildContext context, bool isAndroid14) async {
    // 1. 알림 권한
    await Permission.notification.request();

    // 2. 배터리 최적화 제외
    await Permission.ignoreBatteryOptimizations.request();

    // 3. 다른 앱 위에 표시
    await Permission.systemAlertWindow.request();

    // 4. 🎯 안드로이드 14 이상이면 전체 화면 권한도 요청!
    if (isAndroid14) {
      try {
        await platform.invokeMethod('requestFullScreenIntentPermission');
      } catch (e) {
        debugPrint("FSI request error: $e");
      }
    }

    // 5. 모든 작업 완료 후 메인으로!
    onAllDone();
  }
}
