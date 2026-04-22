# AgroPath KG — что добавить во Flutter для production/demo

## 1) Конфиги окружений
- `lib/config/app_env.dart` — URL API, таймауты, feature-flags.
- `assets/config/dev.json`, `assets/config/prod.json` — внешние настройки без перекомпиляции.

## 2) Данные/модели
- `lib/models/product.dart`
- `lib/models/order.dart`
- `lib/models/farmer_map_point.dart`
- `lib/models/route_compare_result.dart`

## 3) Сетевой слой
- `lib/services/http_client.dart` — единый клиент, retry/timeout/401 handling.
- `lib/services/auth_repository.dart` — login/refresh/logout/verify email.
- `lib/services/order_repository.dart` — create/list/status updates.
- `lib/services/farmers_map_repository.dart` — `/api/farmers/map/`.

## 4) Состояние приложения
- `lib/providers/route_provider.dart`
- `lib/providers/orders_provider.dart`
- `lib/providers/farmers_map_provider.dart`

## 5) UI экраны, которые стоит доделать
- `lib/screens/farmers_map_screen.dart` — карта всех ферм с маркерами.
- `lib/screens/farmer_products_by_map_screen.dart` — товары выбранной фермы с карты.
- `lib/screens/order_status_screen.dart` — трекинг текущего заказа.
- `lib/screens/email_verify_screen.dart` — подтверждение 6-значного кода.

## 6) Виджеты
- `lib/widgets/error_state.dart`
- `lib/widgets/empty_state.dart`
- `lib/widgets/loading_skeleton.dart`

## 7) Локальное хранение
- `lib/storage/secure_token_storage.dart` — токены в secure storage.
- `lib/storage/cart_local_store.dart` — корзина офлайн.

## 8) Тесты
- `test/services/api_service_test.dart`
- `test/providers/auth_provider_test.dart`
- `test/screens/route_screen_test.dart`
- `integration_test/auth_and_order_flow_test.dart`
