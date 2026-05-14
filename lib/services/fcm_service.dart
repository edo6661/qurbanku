import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FcmService {
  // ISI DENGAN KONTEN FILE JSON SERVICE ACCOUNT KAMU
  static const _serviceAccountJson = {
    "type": "service_account",
    "project_id": "qurbanqu-446b0",
    "private_key_id": "190085a08d5157cc898970d4845ac6f6fdb40460",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCnzQUdhrP77vfa\nM8N60/uuJfvv8sI/WZ1pXTFgQ5C+9CLM6Tk3Vn1zDDvK2b2404nl5hl35PQgMk4T\nwRVmkpAXcsGMc0jWFM/4vRBSsjWycgYyZQltws1PFRboZnYcbKzHeXx/W9XBTzdL\nVhCOFPWNiY2IB5kWRbmcoAk4xHYwjfnc36szqMGjPtAduD6L2JVx4nUVd5+xa2Pw\n2VZ9V7ZSQ9/sFxcklRD6SomytrqaaHsh3XqACEQPAzpHsi3zPoSMuS2U6jshefzY\nD4uWiWd9x2GaFC1yqrtQYVFhdX/7lfNdZLeRTo5N8XMjaaXZItIELGIBCDZad6fv\nUtnf9JhdAgMBAAECggEAAcH5iD4le4Gc0gnRxeMbk07tjS1nUH+RUQ27Wy1KAl4P\nUUMuKMC8rqxVogHW5W092A0pfiKFViMAw1816K2nWb+HfH+mpytvpETiu2MHgfeE\nzhlV2HL+cJIhe8y69wBCbRJ+Nd1R52T7iMv9f2eDzPhAZcjilyOi1pusjQ4tyMNn\nnvRU/iyFUWqBnYfYiCe0pA9wfrqisGzmUGfgTA8rs/aTyhdNmU4dUb4YZKM4c2ge\ntQtXCd18i8wmZhl5+WRnfiT6leLRFTs6zDv4Ud+LFSNO7QOCdeTDfodGyDQgsc80\njV9jKdFIbjhLLyan+0E7wIFFVTfJ3syqeYJF7OJyFwKBgQDWGLumIheaLsAs3qDt\nxB3EyoxSC9awN3gTfPWqxa7ChaQbh7K0N9WpAMw5yqquSi5ofBTnWnlFYLhFpD79\ngP+s47HWnz0rV6Y5Ol2ik5I6Y2SuWwL3s+tNIc7+wTIazRTnHjM0H3A+NIZwPxoC\nyrSjrboQRAGvkbwmUSm9XbGONwKBgQDIpKXPje0UFmbCjojXldu09Z3mkGKwzjGv\nzYCWrBykUgUaeH6bAby/2OVevF/rQ4WLOLDdR0wXX4lYHIElTt1e0g8VwGMNKPz1\nmU6CtRRHgwbBS/Tg8fBSqhbGa7eX65rUd+XM1LVjHc8sHluFQc+xgwAVhKvgnyPR\nWsI2vWpkCwKBgQCv6gidfBu6kzlSZOcEFoWDQg5EB/gyOJGQKbfNxrpOmPJ7sGcU\nj2AeikpEHhNaPBefwHyIkB1e9RbUGh2rvEfYbgqc16CyMUWidiOjxu96zFpYrO1m\nTE5FxUbIqkOaI/JN6NGXvVFDu3LPXfnoW1hLuR5N6SMdeHiJX10VfJu8xwKBgQCV\nCC8dHtd1Lzp+0u5z65z5KeNySdb0awPfCG61+/t+VmnyAoRP0JeJjKq6loNMtaex\nBJfilL3BMrZKm0mWE6E8eBy6VF9+e+6A4rG9RpFcmMdgtnGa0DpovGwUUBhboKYt\noS0w2uIsUAz9QUNLlNmXia17TkN4odwx+g7+J+2phwKBgAqW4/qGQr7pAJ4IXPDF\ngEcJ0vQ+Q5U48K5Smx6VxiFauGwqhYRbBVjdlsyOJzPzNaxytygBa3aPnwSCAE9m\nTMBRx+TNuW50i1NpiPI1Zysot2+8mJOrd8E/LOdY0xTu6ouWVrm/HFg4bdbh/ybv\nKBJ35OYaEtNfkbZr+FVY+Q/6\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@qurbanqu-446b0.iam.gserviceaccount.com",
    "client_id": "117091482469388235645",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40qurbanqu-446b0.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future<void> sendNotification({
    required String deviceToken,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Dapatkan akses token dari Google
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(_serviceAccountJson),
        _scopes,
      );

      final projectId = _serviceAccountJson['project_id'];
      final url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // 2. Buat Body Notifikasi
      final message = {
        'message': {
          'token': deviceToken,
          'notification': {'title': title, 'body': body},
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
          },
        },
      };

      // 3. Kirim ke FCM
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        print('✅ Push notif berhasil dikirim!');
      } else {
        print('❌ Gagal kirim. Status: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('Error FCM: $e');
    }
  }
}
