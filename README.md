# Pixel Bakery Home Web (Flutter)

Project Flutter mới dựng lại từ frame `Home Web` trong `8bit_bakery.pen`.

## Chạy project

```bash
flutter pub get
flutter run -d chrome
```

## File chính

- `lib/main.dart`: Toàn bộ UI Home Web.

## State Pattern

Pattern được chuẩn hóa theo hướng `ScreenController + immutable ViewState + Effect`:

- `ScreenController<TState, TEffect>` nằm ở `lib/app/state/screen_controller.dart`.
- `TState` chỉ chứa dữ liệu render, luôn immutable và có `copyWith`.
- `TEffect` dùng cho one-shot side effect như navigation, không nhét vào state.
- UI đọc từng lát state qua `ControllerSelector` để tránh rebuild cả cây.

Quy ước áp dụng cho mỗi screen:

1. Tạo `...ViewState` immutable.
2. Tạo `...State extends ScreenController<...ViewState, ...Effect>`.
3. Với action chỉ đổi UI, gọi `update((current) => current.copyWith(...))`.
4. Với action như điều hướng, toast, dialog, gọi `emit(effect)`.
5. Ở widget root, nghe effect bằng `ControllerEffectListener`.

Ví dụ hiện đã áp dụng:

- `lib/screens/auth/*`: bỏ `pendingNav`, chuyển sang effect stream.
- `lib/screens/home/*`: navigation tách khỏi render-state.
- `lib/screens/menu/*` và `lib/screens/voucher/*`: dùng `ControllerSelector` để rebuild theo field thay vì nghe toàn bộ controller.

## Network Layer

Tầng network nằm ở `lib/app/network` và `lib/app/services`:

- `ApiConfig`: đọc `API_BASE_URL` và timeout từ `--dart-define`.
- `ApiClient`: xử lý `GET/POST/PUT/PATCH/DELETE`, header, auth token, timeout, decode JSON.
- `ApiResponse<T>`: chuẩn hóa response thành object typed.
- `ApiException`: chuẩn hóa lỗi API/network để UI hoặc state layer xử lý thống nhất.
- `BaseApiRepository`: helper parse object/list cho repository theo feature.
- `AppServices`: bootstrap singleton để app có một `ApiClient` dùng chung.

Chạy app với base URL:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://your-api-domain.com
```
