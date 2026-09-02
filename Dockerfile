# Reproducible Flutter build/test environment for CI and local verification.
# Usage:
#   docker build -t bookly-ci .
#   docker run --rm bookly-ci flutter test
#   docker run --rm bookly-ci flutter build apk --release
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter pub get

CMD ["flutter", "analyze"]
