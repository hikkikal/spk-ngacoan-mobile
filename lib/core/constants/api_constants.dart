class ApiConstants {
  static const String baseUrl = 'https://spkngacoan.fbariaja.my.id/api/v1';

  // Auth
  static const String login = '/login';
  static const String me = '/me';
  static const String logout = '/logout';

  // Forgot Password
  static const String sendOtp = '/forgot-password/send-otp';
  static const String resetPassword = '/forgot-password/reset';

  // Supplier
  static const String suppliers = '/suppliers';

  // Criteria
  static const String criteria = '/criteria';

  // Evaluations
  static const String evaluations = '/evaluations';
  static const String evaluationsBulk = '/evaluations/bulk';

  // EDAS
  static const String calculateEdas = '/calculate-edas';

  // Decision History
  static const String decisionHistories = '/decision-histories';

  // Dashboard
  static const String dashboardStats = '/dashboard-stats';

  // Users
  static const String users = '/users';
}