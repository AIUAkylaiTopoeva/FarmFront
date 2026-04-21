# Как перенести эти изменения в свой репозиторий

Ниже 3 рабочих варианта — выбери удобный.

## Вариант 1 (самый простой): через Pull Request
1. Открой PR с этими изменениями.
2. Нажми **Merge** в GitHub/GitLab.
3. На своей машине выполни:

```bash
git checkout <твоя-ветка>
git pull
```

## Вариант 2: cherry-pick конкретных коммитов
Если изменения уже есть в другой ветке/клоне, можно перенести точечно:

```bash
git checkout <твоя-ветка>
git cherry-pick 7fbf2de
git cherry-pick c839894
```

Если будут конфликты:

```bash
git status
# исправь файлы вручную
git add .
git cherry-pick --continue
```

## Вариант 3: руками по файлам (если хочешь выборочно)
Обнови только нужные файлы:

- `lib/services/api_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/route_screen.dart`
- `lib/screens/farmer_home_screen.dart`
- `lib/screens/add_product_screen.dart`
- `docs/mobile_production_checklist.md`

После этого:

```bash
git add .
git commit -m "Integrate mobile flow improvements"
git push
```

## Что важно проверить после переноса
1. В `route_screen.dart` маршрут пересчитывается с пользовательскими `fuel_price` и `fuel_consumption`.
2. В `farmer_home_screen.dart` кнопка **Добавить** открывает `AddProductScreen`.
3. В `add_product_screen.dart` есть category dropdown + quantity + image URL.
4. В `api_service.dart` есть методы `createProduct(...)` и расширенный `compareRoutes(...)`.
5. Splash выполняет bootstrap сессии и маршрутизацию по роли.

## Частая ошибка
Если backend не принимает новые поля, временно убери их из payload в `compareRoutes(...)` и `createProduct(...)` и сверяйся со Swagger (`/swagger/`).
