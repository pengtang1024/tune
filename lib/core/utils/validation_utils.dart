/// 表单校验工具类
class ValidationUtils {
  /// 校验邮箱格式
  static bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 校验手机号格式
  static bool isValidPhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 校验密码强度（至少8位，包含数字和字母）
  static bool isValidPassword(String password) {
    if (password.length < 8) {
      return false;
    }

    final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final bool hasDigit = RegExp(r'\d').hasMatch(password);

    return hasLetter && hasDigit;
  }

  /// 校验用户名（3-20位，只能包含字母、数字、下划线）
  static bool isValidUsername(String username) {
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }
}