import 'package:flutter/material.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';

/// Destino tras el intro (o al saltarlo en recarga web).
Widget buildPostIntroHome() {
  final hasToken = TokenService().hasToken();
  if (hasToken) {
    // ignore: discarded_futures
    ChatPushService().initialize();
  }
  return hasToken ? const DashboardPage() : const LoginPage();
}
