class ApiConfig {
  // ✅ YOUR RENDER BACKEND URL
  static const String baseUrl = "https://remindme-backend-x1qd.onrender.com";

  static const String sendOtp = "$baseUrl/api/auth/sendotp";
  static const String verifyOtp = "$baseUrl/api/auth/verifyotp";
  static const String login = "$baseUrl/api/auth/login";
  static const String getProfile = "$baseUrl/api/auth/profile";
  static const String updateProfile = "$baseUrl/api/auth/update";

  static const String addMedicine = "$baseUrl/api/medicine/addMedicine";
  static const String viewMedicine = "$baseUrl/api/medicine/getMedicine";
  static const String updateMedicine = "$baseUrl/api/medicine/updateMedicine";
  static const String deleteMedicine = "$baseUrl/api/medicine/deleteMedicine";

  static const String inviteCaregiver =
      "$baseUrl/api/relationship/invite/caregiver";
  static const String invitePatient =
      "$baseUrl/api/relationship/invite/patient";
  static const String addRelationship = "$baseUrl/api/relationship/addrelation";

  static const String respondToInvite =
      "$baseUrl/api/relationship/respond-invite";

  static const String getCaregivers = "$baseUrl/api/relationship/caregivers";
  static const String getPatients = "$baseUrl/api/relationship/patients";
  static const String deleteRelation = "$baseUrl/api/relationship/delete";

  static const String logAction = "$baseUrl/api/medicine/action";
  static const String getReport = "$baseUrl/api/medicine/report";
}
