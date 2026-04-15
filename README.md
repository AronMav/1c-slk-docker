# СЛК 3.0 — развёртывание в Docker

Сервер лицензирования СЛК 3.0 в Docker-контейнере на базе Debian Bookworm.
Используется программный ключ (аппаратный USB UPKey не поддерживается).

## Структура

```
SLK/
├── Dockerfile                      # Образ на debian:bookworm-slim
├── docker-compose.yml              # Запуск контейнера
├── .dockerignore                   # В образ попадает только .deb пакет
├── .gitignore                      # В репозиторий попадает только эта конфигурация
├── README.md
├── licence.series                  # Файл серий лицензий (из дистрибутива)
├── licenceserver-X.X.X/            # Каталог с дистрибутивом (версия подставляется)
│   └── licenceserver-*.amd64.deb  # Пакет установки для Linux x86_64
└── docker/
    └── licenceserver.conf          # Конфигурация сервера для Docker
```

## Требования

- Docker Engine 20.10+
- Docker Compose v2+
- Код активации в формате `XXXX-XXXX-XXXX-XXXX`
- Доступ к интернету для активации (licencecenter.ru)

## Первый запуск

### 1. Задать MAC-адрес контейнера

Программный ключ при активации привязывается к аппаратному отпечатку машины.
Чтобы привязка сохранялась между перезапусками контейнера, MAC-адрес должен быть зафиксирован.

Откройте `docker-compose.yml` и задайте произвольный, но постоянный MAC:

```yaml
mac_address: "02:42:ac:11:00:02"
```

> Значение можно оставить как есть или задать любое в формате `XX:XX:XX:XX:XX:XX`.
> Главное — не менять его после активации ключа.

### 2. Собрать образ и запустить

```bash
docker compose up -d --build
```

Каталог `docker/keys/` на этом шаге пуст — это нормально.

### 3. Активировать ключ

Откройте веб-консоль: `http://localhost:9099`

Логин/пароль по умолчанию: `admin` / `admin`

В веб-консоли перейдите в раздел установки ключей и введите код активации
в формате `XXXX-XXXX-XXXX-XXXX`. Сервер обратится на licencecenter.ru,
активирует ключ и сохранит файлы лицензии в `docker/keys/` автоматически.

### 4. Проверить

```bash
# Статус контейнера
docker ps

# Логи
docker logs slk-licenceserver
```

После активации файлы `*.licence` сохраняются в именованном томе `slk-keys`,
которым управляет Docker. Посмотреть содержимое тома можно командой:

```bash
docker run --rm -v slk-keys:/data alpine ls /data
```

---

## Обновление версии СЛК

1. Распакуйте новый дистрибутив рядом со старым каталогом `licenceserver-X.X.X/`
2. Удалите старый каталог
3. Пересоберите образ:

```bash
docker compose up -d --build
```

Файлы ключей (`docker/keys/`) и конфигурация (`docker/licenceserver.conf`) не затрагиваются.

---

## Управление контейнером

```bash
# Запуск
docker compose up -d

# Остановка
docker compose down

# Перезапуск
docker compose restart

# Логи в реальном времени
docker logs -f slk-licenceserver
```

---

## Восстановление ключей

Если ключ перестал работать (смена MAC, пересоздание контейнера):

1. Откройте веб-консоль `http://localhost:9099`
2. Воспользуйтесь функцией восстановления ключа через резервный код
3. Либо повторно введите исходный код активации `XXXX-XXXX-XXXX-XXXX`

По вопросам активации: [katran@1c.ru](mailto:katran@1c.ru) или [licencecenter.ru](https://licencecenter.ru)

---

## Конфигурация

Основной конфиг: [docker/licenceserver.conf](docker/licenceserver.conf)

| Параметр | Значение | Описание |
|---|---|---|
| `ServerPort` | `9099` | Порт сервера (менять также в `docker-compose.yml`) |
| `UPKey.Enabled` | `0` | Аппаратные ключи отключены |
| `API.Enabled` | `1` | Внешнее API включено |
| `Console.LocalAccessOnly` | `0` | Веб-консоль доступна с любого IP |
| `LicenceCenterUrl` | `http://prom.licencecenter.ru` | Центр лицензирования |

---

## Внутренние пути в контейнере

| Путь | Назначение |
|---|---|
| `/opt/1C/licence/3.0/licenceserver` | Исполняемый файл сервера |
| `/var/1C/licence/3.0/licenceserver.conf` | Конфигурационный файл |
| `/var/1C/licence/3.0/licence.series` | Файл серий лицензий |
| `/var/1C/licence/data/*.licence` | Файлы программных ключей (том `slk-keys`) |
