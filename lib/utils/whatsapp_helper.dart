import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class WhatsAppHelper {
  static Future<void> openAdminChat({String? message}) async {
    final text = Uri.encodeComponent(message ?? AppConstants.defaultWaMessage);
    final uri = Uri.parse(
      'https://wa.me/${AppConstants.adminWhatsApp}?text=$text',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }
}
