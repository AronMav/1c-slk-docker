FROM debian:bookworm-slim

# libusb-1.0-0 — обязательная зависимость пакета (Pre-depends)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Установка пакета сервера СЛК
# postinst проверяет pidof systemd / pidof /sbin/init — в контейнере оба отсутствуют,
# поэтому systemd-интеграция молча пропускается, dpkg завершается успешно
COPY licenceserver-*/licenceserver-*.amd64.deb /tmp/
RUN dpkg -i /tmp/licenceserver-*.amd64.deb && rm /tmp/licenceserver-*.amd64.deb

# Директория для данных: конфиг, серия, файлы программных ключей
RUN mkdir -p /var/1C/licence/3.0

# Порт веб-консоли и API сервера СЛК (задаётся в licenceserver.conf → ServerPort)
EXPOSE 9099

# Запуск в режиме переднего плана (-r = run / foreground)
CMD ["/opt/1C/licence/3.0/licenceserver", "-r"]
