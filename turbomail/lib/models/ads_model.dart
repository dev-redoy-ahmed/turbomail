class AdsConfig {
  final String id;
  final String adType;
  final String adId;
  final String platform;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdsConfig({
    required this.id,
    required this.adType,
    required this.adId,
    required this.platform,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    return AdsConfig(
      id: json['_id'] ?? '',
      adType: json['adType'] ?? '',
      adId: json['adId'] ?? '',
      platform: json['platform'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'adType': adType,
      'adId': adId,
      'platform': platform,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AdsConfig(id: $id, adType: $adType, adId: $adId, platform: $platform, isActive: $isActive)';
  }
}

class AppUpdateModel {
  final String id;
  final String versionName;
  final int versionCode;
  final String platform;
  final bool isForceUpdate;
  final bool isNormalUpdate;
  final bool isActive;
  final String updateMessage;
  final String updateLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUpdateModel({
    required this.id,
    required this.versionName,
    required this.versionCode,
    required this.platform,
    required this.isForceUpdate,
    required this.isNormalUpdate,
    required this.isActive,
    required this.updateMessage,
    required this.updateLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      id: json['_id'] ?? '',
      versionName: json['versionName'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      platform: json['platform'] ?? '',
      isForceUpdate: json['isForceUpdate'] ?? false,
      isNormalUpdate: json['isNormalUpdate'] ?? false,
      isActive: json['isActive'] ?? false,
      updateMessage: json['updateMessage'] ?? '',
      updateLink: json['updateLink'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'versionName': versionName,
      'versionCode': versionCode,
      'platform': platform,
      'isForceUpdate': isForceUpdate,
      'isNormalUpdate': isNormalUpdate,
      'isActive': isActive,
      'updateMessage': updateMessage,
      'updateLink': updateLink,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppUpdateModel(id: $id, versionName: $versionName, versionCode: $versionCode, platform: $platform, isActive: $isActive)';
  }
}