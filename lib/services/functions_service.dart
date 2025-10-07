import 'package:cloud_functions/cloud_functions.dart';
import '../config/backend.dart';

class FunctionsService {
  FunctionsService({FirebaseFunctions? functions})
      : functions = functions ??
            FirebaseFunctions.instanceFor(region: BackendConfig.firebaseRegion);

  final FirebaseFunctions functions;

  Future<String?> getEnrollmentPaymentStatus(String enrollmentId) async {
    final callable =
        functions.httpsCallable(BackendConfig.fnGetEnrollmentPaymentStatus);
    final resp = await callable.call(<String, dynamic>{
      'enrollmentId': enrollmentId,
    });
    final data = (resp.data as Map?) ?? const {};
    final status = data['status'] as String?;
    return status;
  }

  Future<void> sendMessageToUser(
      {required String toUserId, required String text}) async {
    final callable = functions.httpsCallable(BackendConfig.fnSendMessage);
    await callable.call(<String, dynamic>{
      'toUserId': toUserId,
      'text': text,
    });
  }

  Future<Map<String, dynamic>> chatbotReply(String prompt) async {
    final callable = functions.httpsCallable(BackendConfig.fnChatbotReply);
    final resp = await callable.call(<String, dynamic>{'prompt': prompt});
    final data =
        (resp.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (!data.containsKey('reply') && resp.data is String) {
      return {'reply': resp.data as String};
    }
    return data;
  }
}
