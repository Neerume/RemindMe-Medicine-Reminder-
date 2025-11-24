  class ApiConfig{
    static const String baseUrl = "https://remindme-backend-x1qd.onrender.com";
    // Auth endpoints
    static const String sendOtp = "$baseUrl/api/auth/sendotp";
    static const String verifyOtp = "$baseUrl/api/auth/verifyotp";
    static const String login = "$baseUrl/api/auth/login";
    static const String getProfile= "$baseUrl/api/auth/profile";
    static const String updateProfile= "$baseUrl/api/auth/update";

    //medicine endpoints
  static const String addMedicine = "$baseUrl/api/medicine/addMedicine";
  static const String viewMedicine = "$baseUrl/api/medicine/getMedicine";
  static const String updateMedicine = "$baseUrl/api/medicine/updateMedicine";
  static const String deleteMedicine = "$baseUrl/api/medicine/deleteMedicine";



  }
