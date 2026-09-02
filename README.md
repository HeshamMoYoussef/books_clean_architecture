<div align="center">

# 📚 Bookly — Clean Architecture Reference App

### A production-grade Flutter reference implementation of Clean Architecture + Cubit

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Bloc/Cubit](https://img.shields.io/badge/State-Bloc%2FCubit-02569B?style=flat-square)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-6C757D?style=flat-square)
![get_it](https://img.shields.io/badge/DI-get__it-8B5CF6?style=flat-square)
![Hive](https://img.shields.io/badge/Cache-Hive-FFC107?style=flat-square)
![Dio](https://img.shields.io/badge/Networking-Dio-13B9FD?style=flat-square)
![CI](https://github.com/HeshamMoYoussef/books_clean_architecture/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## 📖 Overview

**Bookly** is a Google Books–powered catalog app built to demonstrate how a real Flutter application should be architected: strict layering, dependency inversion, and testable business logic — decoupled from any framework or UI concern.

It is intentionally kept feature-focused (Home / Search / Book Details) so the **architecture itself** is the artifact under review, not feature count.

---

## 🏗 Architecture

The project follows **Clean Architecture** with a **feature-first** folder structure. Each feature (`home`, `search`, `splash`) owns its own `data → domain → presentation` stack, isolated behind interfaces so outer layers never leak into inner ones.

```
lib/
├── core/                         # Cross-cutting: DI, routing, errors, shared widgets
│   ├── errors/                   # Failure types (Either<Failure, T>)
│   ├── use_cases/                # Base UseCase<Type, Params> contract
│   └── utils/                    # api_service, app_router, service locator
│
└── Features/
    └── home/
        ├── data/
        │   ├── data_sources/     # Remote (Dio/API) & Local (Hive) sources
        │   ├── models/           # DTOs — fromJson/toJson, extend domain entities
        │   └── repos/            # HomeRepoImpl — implements domain contract
        ├── domain/
        │   ├── entities/         # Pure business objects, no framework deps
        │   ├── repos/            # Abstract HomeRepo contract
        │   └── use_cases/        # FetchFeaturedBooksUseCase, FetchNewestBooksUseCase
        └── presentation/
            ├── manger/           # Cubits + States (FeaturedBooksCubit, NewestBooksCubit)
            └── views/            # Screens & widgets (framework/UI only)
```

### Data Flow

```
┌──────────────┐      user intent      ┌──────────────┐
│    View      │ ─────────────────────▶│    Cubit     │
│ (Widgets)    │◀───────────────────── │ (Presentation)│
└──────────────┘      emit(State)      └──────┬───────┘
                                               │ calls
                                               ▼
                                        ┌──────────────┐
                                        │   UseCase    │   core/use_cases/use_case.dart
                                        │  (Domain)    │   UseCase<Type, Params>
                                        └──────┬───────┘
                                               │ depends on (interface)
                                               ▼
                                        ┌──────────────┐
                                        │  HomeRepo    │   abstract contract
                                        │  (Domain)    │
                                        └──────▲───────┘
                                               │ implements
                                        ┌──────┴───────┐
                                        │HomeRepoImpl  │   (Data)
                                        └──┬────────┬──┘
                                 ┌─────────┘        └─────────┐
                                 ▼                            ▼
                        ┌────────────────┐          ┌──────────────────┐
                        │ RemoteDataSource│         │  LocalDataSource   │
                        │  (Dio → API)    │         │  (Hive cache)      │
                        └────────────────┘          └──────────────────┘
```

**Dependency rule:** arrows for *compile-time dependencies* always point inward — `presentation → domain ← data`. The `domain` layer has zero knowledge of Dio, Hive, or Flutter widgets, which is what makes the use cases and entities independently testable.

| Layer | Responsibility | Depends on |
|---|---|---|
| **Presentation** | Cubits, states, views/widgets | Domain (use cases) |
| **Domain** | Entities, repo contracts, use cases | Nothing (pure Dart) |
| **Data** | Models, remote/local data sources, repo implementations | Domain (implements contracts) |

### State Management

- **`flutter_bloc` (Cubit)** per feature slice — `FeaturedBooksCubit`, `NewestBooksCubit` — each with a sealed `State` (`Initial / Loading / Success / Failure`).
- **`get_it`** as the service locator, wired in `core/utils/functions/setup_service_locator.dart`, injecting data sources → repo → use cases → cubits.
- **`dartz`**'s `Either<Failure, T>` propagates errors from data sources up through use cases without throwing across layer boundaries.

---

## 🚀 Installation & Production Setup

### Prerequisites

- Flutter SDK `>=3.1.3 <4.0.0` (stable channel)
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode for platform builds
- A Google Books API key (optional — public endpoints work unauthenticated at low volume)

### Local Development

```bash
git clone https://github.com/HeshamMoYoussef/books_clean_architecture.git
cd books_clean_architecture

flutter pub get
flutter run
```

### Code Generation

Hive type adapters are generated via `build_runner`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Quality Gates (run before every commit)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

### Production Builds

```bash
# Android — release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Android — Play Store App Bundle
flutter build appbundle --release

# iOS — release archive
flutter build ipa --release
```

### Containerized / Reproducible Build

A `Dockerfile` is provided for a deterministic build & test environment (matches CI):

```bash
docker build -t bookly-ci .
docker run --rm bookly-ci flutter test
docker run --rm bookly-ci flutter build apk --release
```

---

## 🔁 DevOps & Automation

| Concern | Tooling | Location |
|---|---|---|
| **Continuous Integration** | GitHub Actions | `.github/workflows/ci.yml` |
| **Format Gate** | `dart format --set-exit-if-changed` | CI, pre-commit |
| **Static Analysis** | `flutter analyze` + `flutter_lints` | CI, `analysis_options.yaml` |
| **Automated Tests** | `flutter test` | CI |
| **Reproducible Builds** | Docker (`cirruslabs/flutter:stable` image) | `Dockerfile` |
| **Release Artifacts** | Android release APK uploaded per CI run | CI workflow artifact |

CI pipeline (`ci.yml`) runs on every push/PR to `main`:

1. **`analyze-and-test`** — install deps → verify formatting → static analysis → unit/widget tests
2. **`build-android`** *(gated on job 1 passing)* — release APK build, uploaded as a downloadable artifact

This mirrors a minimal production release gate: nothing merges to `main` without passing formatting, lint, and test checks, and every green build produces an installable artifact.

---

## 🧪 Testing Strategy

- **Unit tests** target use cases and repository implementations in isolation, mocking data sources via the abstract `domain` contracts.
- **Widget tests** (`test/widget_test.dart`) verify presentation-layer behavior without touching real network/cache.
- The `UseCase<Type, Params>` contract (`core/use_cases/use_case.dart`) makes every use case trivially mockable — no framework bootstrapping required to test business rules.

---

## 📦 Tech Stack

| Concern | Package |
|---|---|
| State Management | `flutter_bloc` (Cubit) |
| Dependency Injection | `get_it` |
| Networking | `dio` |
| Local Cache | `hive`, `hive_flutter` |
| Functional Error Handling | `dartz` (`Either<Failure, T>`) |
| Routing | `go_router` |
| Image Loading | `cached_network_image` |
| Fonts/Icons | `google_fonts`, `font_awesome_flutter` |

---

## 🛰 Modernization Roadmap

Documented here as an honest forward-look, not implemented in this reference repo:

- **Offline-first cache-through repository**: `HomeRepoImpl` already reads from Hive on failure — the natural next step is a stale-while-revalidate strategy so the UI never blocks on network latency for previously-seen data.
- **CI-integrated golden/widget-diff testing** to catch presentation regressions automatically, extending the current `analyze-and-test` job.
- **AI-assisted code review gating** (e.g. an MCP-connected review agent in CI) as a second automated reviewer alongside `flutter analyze`, flagging architectural-boundary violations before merge.
- **Modular federation** of the `home`/`search`/`splash` features into independently versioned packages once a second consumer app needs to share this catalog logic.

---

## 📂 Project Structure Philosophy

This repo is a **teaching reference**, not a feature-complete product. The goal is to demonstrate:

1. How **dependency inversion** keeps `domain` free of framework code.
2. How **Cubits** stay thin by delegating all business logic to use cases.
3. How **DI wiring** (`get_it`) assembles the dependency graph at app startup, not at call sites.
4. How **CI automation** enforces the same quality bar as a production team would.

---

<div align="center">

Made with 💙 by [Hesham Mohamed Youssef](https://github.com/HeshamMoYoussef) — showcasing Clean Architecture in production Flutter apps.

</div>
