class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    // University email validation — must end with .edu or .edu.pk etc.
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.(edu|edu\.pk|ac\.pk)$');
    if (!emailRegex.hasMatch(value.toLowerCase())) {
      return 'Please use your university email (e.g. name@uni.edu.pk)';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return null; // price is optional
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) return 'Enter a valid price';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }
}
