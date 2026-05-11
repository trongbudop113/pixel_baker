class ContactInfoCardModel {
  const ContactInfoCardModel({
    required this.title,
    this.lines = const [],
    this.previewLabel,
  });

  final String title;
  final List<String> lines;
  final String? previewLabel;

  bool get isPreviewCard => previewLabel != null;

  factory ContactInfoCardModel.fromJson(Map<String, dynamic> json) {
    return ContactInfoCardModel(
      title: (json['title'] ?? '').toString(),
      lines: ((json['lines'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      previewLabel: json['previewLabel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lines': lines,
      'previewLabel': previewLabel,
    };
  }
}

class ContactFormFieldModel {
  const ContactFormFieldModel({
    required this.label,
    required this.placeholder,
    this.multiline = false,
  });

  final String label;
  final String placeholder;
  final bool multiline;

  factory ContactFormFieldModel.fromJson(Map<String, dynamic> json) {
    return ContactFormFieldModel(
      label: (json['label'] ?? '').toString(),
      placeholder: (json['placeholder'] ?? '').toString(),
      multiline: json['multiline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'placeholder': placeholder,
      'multiline': multiline,
    };
  }
}

class ContactPageResponse {
  const ContactPageResponse({
    required this.heroTitle,
    required this.heroDescription,
    required this.formTitle,
    required this.submitLabel,
    required this.mobileTitle,
    required this.mobileBadge,
    required this.fields,
    required this.infoCards,
    required this.bottomNavLabels,
  });

  final String heroTitle;
  final String heroDescription;
  final String formTitle;
  final String submitLabel;
  final String mobileTitle;
  final String mobileBadge;
  final List<ContactFormFieldModel> fields;
  final List<ContactInfoCardModel> infoCards;
  final List<String> bottomNavLabels;

  factory ContactPageResponse.fromJson(Map<String, dynamic> json) {
    return ContactPageResponse(
      heroTitle: (json['heroTitle'] ?? '').toString(),
      heroDescription: (json['heroDescription'] ?? '').toString(),
      formTitle: (json['formTitle'] ?? '').toString(),
      submitLabel: (json['submitLabel'] ?? '').toString(),
      mobileTitle: (json['mobileTitle'] ?? '').toString(),
      mobileBadge: (json['mobileBadge'] ?? '').toString(),
      fields: ((json['fields'] as List?) ?? const [])
          .map((item) => ContactFormFieldModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      infoCards: ((json['infoCards'] as List?) ?? const [])
          .map((item) => ContactInfoCardModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      bottomNavLabels: ((json['bottomNavLabels'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heroTitle': heroTitle,
      'heroDescription': heroDescription,
      'formTitle': formTitle,
      'submitLabel': submitLabel,
      'mobileTitle': mobileTitle,
      'mobileBadge': mobileBadge,
      'fields': fields.map((item) => item.toJson()).toList(growable: false),
      'infoCards':
          infoCards.map((item) => item.toJson()).toList(growable: false),
      'bottomNavLabels': bottomNavLabels,
    };
  }
}

class ContactSubmitRequest {
  const ContactSubmitRequest({
    required this.fullName,
    required this.email,
    this.phone,
    required this.message,
  });

  final String fullName;
  final String email;
  final String? phone;
  final String message;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'message': message,
    };
  }
}

const ContactPageResponse defaultContactPageResponse = ContactPageResponse(
  heroTitle: 'Liên hệ 8 Bit Bakery',
  heroDescription: 'Kết nối nhanh, chúng tôi sẽ phản hồi và hỗ trợ sớm nhất.',
  formTitle: 'Biểu mẫu liên hệ',
  submitLabel: 'Gửi liên hệ',
  mobileTitle: 'Liên hệ',
  mobileBadge: 'Hotline',
  fields: [
    ContactFormFieldModel(label: 'Họ và tên', placeholder: 'Họ và tên'),
    ContactFormFieldModel(label: 'Email', placeholder: 'Email'),
    ContactFormFieldModel(
      label: 'Số điện thoại',
      placeholder: 'Số điện thoại',
    ),
    ContactFormFieldModel(
      label: 'Nội dung liên hệ',
      placeholder: 'Nội dung liên hệ',
      multiline: true,
    ),
  ],
  infoCards: [
    ContactInfoCardModel(
      title: 'Thông tin cửa hàng',
      lines: [
        'Hotline: 0909 123 456',
        'Email: support@8bitbakery.vn',
        'Địa chỉ: 123 Lê Lợi, Q1, TP.HCM',
      ],
    ),
    ContactInfoCardModel(
      title: 'Giờ mở cửa',
      lines: [
        'T2-T6: 7:30 - 21:00',
        'Thứ 7 - CN: 8:00 - 22:00',
      ],
    ),
    ContactInfoCardModel(
      title: 'Bản đồ',
      previewLabel: 'Map Preview',
    ),
  ],
  bottomNavLabels: ['Home', 'Menu', 'Liên hệ', 'Profile'],
);
