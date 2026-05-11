class StoryTimelineItemModel {
  const StoryTimelineItemModel({
    required this.year,
    required this.description,
  });

  final String year;
  final String description;

  factory StoryTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return StoryTimelineItemModel(
      year: (json['year'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'description': description,
    };
  }
}

class StoryImageTimelineItemModel {
  const StoryImageTimelineItemModel({
    required this.year,
    required this.title,
    required this.description,
    required this.previewLabel,
  });

  final String year;
  final String title;
  final String description;
  final String previewLabel;

  factory StoryImageTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return StoryImageTimelineItemModel(
      year: (json['year'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      previewLabel: (json['previewLabel'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'title': title,
      'description': description,
      'previewLabel': previewLabel,
    };
  }
}

class StorySectionModel {
  const StorySectionModel({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  factory StorySectionModel.fromJson(Map<String, dynamic> json) {
    return StorySectionModel(
      title: (json['title'] ?? '').toString(),
      items: ((json['items'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items,
    };
  }
}

class StoryCraftSectionModel {
  const StoryCraftSectionModel({
    required this.title,
    required this.description,
    required this.previewLabel,
  });

  final String title;
  final String description;
  final String previewLabel;

  factory StoryCraftSectionModel.fromJson(Map<String, dynamic> json) {
    return StoryCraftSectionModel(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      previewLabel: (json['previewLabel'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'previewLabel': previewLabel,
    };
  }
}

class StoryCtaSectionModel {
  const StoryCtaSectionModel({
    required this.description,
    required this.buttonLabel,
  });

  final String description;
  final String buttonLabel;

  factory StoryCtaSectionModel.fromJson(Map<String, dynamic> json) {
    return StoryCtaSectionModel(
      description: (json['description'] ?? '').toString(),
      buttonLabel: (json['buttonLabel'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'buttonLabel': buttonLabel,
    };
  }
}

class StoryPageResponse {
  const StoryPageResponse({
    required this.headerTitle,
    required this.heroTitle,
    required this.heroDescription,
    required this.heroBadge,
    required this.timelineTitle,
    required this.timelineItems,
    required this.imageTimelineTitle,
    required this.imageTimelineItems,
    required this.values,
    required this.craft,
    required this.cta,
    required this.footerLabel,
  });

  final String headerTitle;
  final String heroTitle;
  final String heroDescription;
  final String heroBadge;
  final String timelineTitle;
  final List<StoryTimelineItemModel> timelineItems;
  final String imageTimelineTitle;
  final List<StoryImageTimelineItemModel> imageTimelineItems;
  final StorySectionModel values;
  final StoryCraftSectionModel craft;
  final StoryCtaSectionModel cta;
  final String footerLabel;

  factory StoryPageResponse.fromJson(Map<String, dynamic> json) {
    return StoryPageResponse(
      headerTitle: (json['headerTitle'] ?? '').toString(),
      heroTitle: (json['heroTitle'] ?? '').toString(),
      heroDescription: (json['heroDescription'] ?? '').toString(),
      heroBadge: (json['heroBadge'] ?? '').toString(),
      timelineTitle: (json['timelineTitle'] ?? '').toString(),
      timelineItems: ((json['timelineItems'] as List?) ?? const [])
          .map((item) => StoryTimelineItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      imageTimelineTitle: (json['imageTimelineTitle'] ?? '').toString(),
      imageTimelineItems: ((json['imageTimelineItems'] as List?) ?? const [])
          .map((item) => StoryImageTimelineItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      values: StorySectionModel.fromJson(
        Map<String, dynamic>.from((json['values'] as Map?) ?? const {}),
      ),
      craft: StoryCraftSectionModel.fromJson(
        Map<String, dynamic>.from((json['craft'] as Map?) ?? const {}),
      ),
      cta: StoryCtaSectionModel.fromJson(
        Map<String, dynamic>.from((json['cta'] as Map?) ?? const {}),
      ),
      footerLabel: (json['footerLabel'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerTitle': headerTitle,
      'heroTitle': heroTitle,
      'heroDescription': heroDescription,
      'heroBadge': heroBadge,
      'timelineTitle': timelineTitle,
      'timelineItems': timelineItems.map((item) => item.toJson()).toList(),
      'imageTimelineTitle': imageTimelineTitle,
      'imageTimelineItems':
          imageTimelineItems.map((item) => item.toJson()).toList(),
      'values': values.toJson(),
      'craft': craft.toJson(),
      'cta': cta.toJson(),
      'footerLabel': footerLabel,
    };
  }
}

const defaultStoryPageResponse = StoryPageResponse(
  headerTitle: 'Câu chuyện thương hiệu',
  heroTitle: 'Câu chuyện Pixel Bakery',
  heroDescription:
      'Từ cảm hứng máy game thùng cổ điển, chúng tôi tạo nên những chiếc bánh tươi mới mỗi ngày với tinh thần vui nhộn, chỉn chu và nhất quán.',
  heroBadge: '100% Làm mới trong ngày',
  timelineTitle: 'Hành trình phát triển',
  timelineItems: [
    StoryTimelineItemModel(
      year: '2021',
      description: 'Bắt đầu từ một góc bếp nhỏ với các mẻ cupcake đầu tiên.',
    ),
    StoryTimelineItemModel(
      year: '2023',
      description: 'Mở rộng menu với cookie, tart và bánh theo mùa.',
    ),
    StoryTimelineItemModel(
      year: '2025',
      description: 'Ra mắt trải nghiệm đặt bánh online theo phong cách Pixel UI.',
    ),
  ],
  imageTimelineTitle: 'Dòng thời gian hình ảnh',
  imageTimelineItems: [
    StoryImageTimelineItemModel(
      year: '2021',
      title: 'Góc bếp đầu tiên',
      description:
          'Những mẻ bánh thử nghiệm đầu tiên được hoàn thiện trong một căn bếp nhỏ nhưng đầy năng lượng.',
      previewLabel: 'Kitchen Corner',
    ),
    StoryImageTimelineItemModel(
      year: '2023',
      title: 'Mở rộng menu',
      description:
          'Không gian làm bánh được nâng cấp để thử nhiều dòng bánh mới và các bộ sưu tập theo mùa.',
      previewLabel: 'Seasonal Lab',
    ),
    StoryImageTimelineItemModel(
      year: '2025',
      title: 'Pixel UI ra mắt',
      description:
          'Trải nghiệm thương hiệu được đồng bộ từ quầy bánh đến website theo ngôn ngữ hình ảnh retro arcade.',
      previewLabel: 'Brand Launch',
    ),
  ],
  values: StorySectionModel(
    title: 'Giá trị cốt lõi',
    items: [
      'Nguyên liệu rõ nguồn gốc, làm mới mỗi ngày.',
      'Hương vị cân bằng, thân thiện với đa số khách hàng.',
      'Dịch vụ nhanh, lịch sự và nhất quán.',
    ],
  ),
  craft: StoryCraftSectionModel(
    title: 'Góc làm bánh',
    description:
        'Mỗi chiếc bánh đi qua 3 bước: phối vị, nướng chuẩn nhiệt, hoàn thiện thủ công. Chúng tôi ưu tiên cấu trúc mềm ẩm và độ ngọt vừa phải.',
    previewLabel: 'Kitchen Preview',
  ),
  cta: StoryCtaSectionModel(
    description: 'Khám phá menu và chọn vị bánh bạn thích ngay hôm nay.',
    buttonLabel: 'XEM THỰC ĐƠN',
  ),
  footerLabel: 'PIXEL BAKERY | STORY',
);
