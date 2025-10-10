// Backend environment configuration for dev/prod and callable/HTTP names.

class BackendConfig {
  BackendConfig._();

  // Firebase
  static const String firebaseRegion = 'asia-south1';
  static const String devProjectId = 'ai-classmate-dev';
  static const String prodProjectId = 'ai-classmate-prod';

  // HTTP endpoints (dev). For prod, swap host prefix to prod project.
  static const String httpBaseDev =
      'https://asia-south1-$devProjectId.cloudfunctions.net';
  static const String httpBaseProd =
      'https://asia-south1-$prodProjectId.cloudfunctions.net';

  // HTTP paths
  static const String pathHealth = '/health';
  static const String pathGetSubjectForecast = '/getSubjectForecast';
  static const String pathGetClassDemandForecast = '/getClassDemandForecast';

  // Callable function names
  static const String fnSetUserRole = 'setUserRole';
  static const String fnPublishClass = 'publishClass';
  static const String fnInitMaterialUpload = 'initMaterialUpload';
  static const String fnGetMyClassDemandForecast = 'getMyClassDemandForecast';
  static const String fnEnrollInClass = 'enrollInClass';
  static const String fnSubmitPaymentProof = 'submitPaymentProof';
  static const String fnRegisterFcmToken = 'registerFcmToken';
  static const String fnSendMessage = 'sendMessage';
  static const String fnGetRecommendationsRealtime =
      'getRecommendationsRealtime';
  static const String fnCreateOrUpdateSession = 'createOrUpdateSession';
  static const String fnScheduleWeeklySessions = 'scheduleWeeklySessions';
  static const String fnGetEnrollmentPaymentStatus =
      'getEnrollmentPaymentStatus';
  static const String fnChatbotReply = 'chatbotReply';

  // Helpers to build full HTTP URLs
  static String healthUrl({bool prod = false}) =>
      (prod ? httpBaseProd : httpBaseDev) + pathHealth;

  static String subjectForecastUrl({bool prod = false}) =>
      (prod ? httpBaseProd : httpBaseDev) + pathGetSubjectForecast;

  static String classDemandForecastUrl({bool prod = false}) =>
      (prod ? httpBaseProd : httpBaseDev) + pathGetClassDemandForecast;
}
