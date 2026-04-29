// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Vườn rau';

  @override
  String get dashboardTitle => 'Vườn rau';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsTooltip => 'Cài đặt';

  @override
  String get fullscreenCameraTooltip => 'Toàn màn hình camera';

  @override
  String get refreshTooltip => 'Làm mới';

  @override
  String get deviceInfoTooltip => 'Thông tin thiết bị';

  @override
  String get historyDetailButton => 'Chi tiết';

  @override
  String get historyTitle => 'Lịch sử độ ẩm & van nước';

  @override
  String get historyFromLabel => 'Từ';

  @override
  String get historyToLabel => 'Đến';

  @override
  String get historyIncludeHumidity => 'Độ ẩm';

  @override
  String get historyIncludeValve => 'Van';

  @override
  String get historySearchButton => 'Tìm';

  @override
  String get historyLoadMore => 'Xem thêm';

  @override
  String get historyColumnTime => 'Ngày giờ';

  @override
  String get historyColumnValue => 'Thông số';

  @override
  String get historyRangeMax3Days => 'Mỗi lần chỉ xem tối đa 3 ngày.';

  @override
  String get historySelectOneType => 'Chọn độ ẩm và/hoặc van.';

  @override
  String get waterValveSectionTitle => 'Điều khiển van nước';

  @override
  String humidityRawLabel(Object value) {
    return 'Độ ẩm (raw): $value';
  }

  @override
  String lastUpdatedLabel(Object value) {
    return 'Cập nhật gần nhất: $value';
  }

  @override
  String get waterValveSwitchLabel => 'Van nước';

  @override
  String get pressRefreshHint => 'Nhấn làm mới để tải trạng thái.';

  @override
  String valveStateLabel(Object value) {
    return 'Van: $value';
  }

  @override
  String uptimeTimestampLabel(Object value) {
    return 'Dấu thời gian uptime: $value';
  }

  @override
  String lastUpdatedBackendLabel(Object value) {
    return 'Cập nhật (backend): $value';
  }

  @override
  String get valveOn => 'BẬT';

  @override
  String get valveOff => 'TẮT';

  @override
  String get unknownState => 'Không rõ';

  @override
  String get missingLabel => '(thiếu)';

  @override
  String get statusCannotReachBackendTitle => 'Không thể kết nối Backend';

  @override
  String statusCannotReachBackendSubtitle(Object baseUrl, Object error) {
    return 'Base URL: $baseUrl\n$error';
  }

  @override
  String get statusBackendCannotReachMqttTitle =>
      'Backend không kết nối được MQTT';

  @override
  String statusBackendCannotReachMqttSubtitle(Object baseUrl) {
    return 'Base URL: $baseUrl\nKiểm tra broker / mạng. Lệnh điều khiển có thể thất bại (503).';
  }

  @override
  String get statusDeviceNotReportingTitle => 'Thiết bị không gửi trạng thái';

  @override
  String statusDeviceNotReportingSubtitle(Object baseUrl, Object ageLabel) {
    return 'Base URL: $baseUrl\nTuổi trạng thái: $ageLabel. Kiểm tra ESP32 nguồn/Wi‑Fi/topic MQTT.';
  }

  @override
  String get statusAllSystemsOkTitle => 'Hệ thống ổn định';

  @override
  String statusAllSystemsOkSubtitle(Object baseUrl) {
    return 'Base URL: $baseUrl\nBackend OK. MQTT OK. Trạng thái thiết bị mới.';
  }

  @override
  String get retryButton => 'Thử lại';

  @override
  String get backendBaseUrlLabel => 'Backend base URL';

  @override
  String get backendBaseUrlHint => 'http://192.168.1.10:8000';

  @override
  String get ezvizAccessTokenLabel => 'Token truy cập EZVIZ';

  @override
  String get ezvizAccessTokenHint => 'Dán token từ EZVIZ OpenAPI / console';

  @override
  String get ezvizAccessTokenHelper =>
      'Để trống để dùng token từ bản build (--dart-define), nếu đã cấu hình.';

  @override
  String get technicalInfoTitle => 'Thông tin kỹ thuật';

  @override
  String deviceLabel(Object deviceId) {
    return 'Thiết bị: $deviceId';
  }

  @override
  String backendToMqttLabel(Object value) {
    return 'Backend→MQTT: $value';
  }

  @override
  String get connectedLabel => 'Kết nối';

  @override
  String get disconnectedLabel => 'Mất kết nối';

  @override
  String get unknownLabel => '-';

  @override
  String stateAgeLabel(Object value) {
    return 'Tuổi trạng thái: $value';
  }

  @override
  String staleLabel(Object value) {
    return 'Stale: $value';
  }

  @override
  String get yesLabel => 'Có';

  @override
  String get noLabel => 'Không';

  @override
  String get expandTitle => 'Mở rộng';

  @override
  String get automationSoon => 'Tự động tưới (sắp có)';

  @override
  String get notificationsSoon => 'Thông báo (sắp có)';

  @override
  String get ezvizCameraTitle => 'Camera EZVIZ';

  @override
  String ptzStartFailed(Object message) {
    return 'Không điều khiển được PTZ: $message';
  }

  @override
  String ptzError(Object message) {
    return 'PTZ lỗi: $message';
  }

  @override
  String get startCamera => 'Bật camera';

  @override
  String get cameraPausedLabel => 'Tạm dừng';

  @override
  String get ezvizNotSupportedWeb => 'EZVIZ không hỗ trợ trên Web';

  @override
  String get ezvizOnlyAndroidIos => 'EZVIZ chỉ hỗ trợ Android/iOS';

  @override
  String get stopTooltip => 'Dừng';

  @override
  String get missingAccessTokenBanner =>
      'Chưa có token EZVIZ: mở Cài đặt và dán access token (hoặc build với --dart-define=EZVIZ_ACCESS_TOKEN=...).';

  @override
  String cameraSourceLabel(Object value) {
    return 'Nguồn: $value';
  }

  @override
  String cameraApiAuthLabel(Object apiUrl, Object authUrl) {
    return 'API: $apiUrl   AUTH: $authUrl';
  }

  @override
  String cameraAppKeyTokenLabel(Object appKeyPrefix, Object tokenPrefix) {
    return 'AppKey: $appKeyPrefix…   Token: $tokenPrefix';
  }
}
