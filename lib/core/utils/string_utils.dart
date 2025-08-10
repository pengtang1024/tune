/// 字符串工具类
class StringUtils {
  /// 检查字符串是否为空或只包含空白字符
  static bool isBlank(String? str) {
    return str?.trim().isEmpty ?? true;
  }

  /// 检查字符串是否不为空且不只包含空白字符
  static bool isNotBlank(String? str) {
    return !isBlank(str);
  }

  /// 截取字符串，超过指定长度后添加省略号
  static String truncateWithEllipsis(String str, int maxLength) {
    if (str.length <= maxLength) {
      return str;
    }
    return '${str.substring(0, maxLength)}...';
  }

  /// 首字母大写
  static String capitalize(String str) {
    if (str.isEmpty) {
      return str;
    }
    return '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}';
  }

  /// 隐藏手机号中间四位
  static String maskPhoneNumber(String phone) {
    if (phone.length < 7) {
      return phone;
    }
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
}