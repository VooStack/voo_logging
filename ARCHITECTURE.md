# Voo Logging Architecture

## Overview

Voo Logging follows a **Feature-Based Clean Architecture** pattern, combining the benefits of clean architecture with feature-based organization for maximum scalability and maintainability.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Layer                        │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │   Core Feature  │  │ Logging Feature  │  │DevTools Feature│ │
│  └─────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────┐
│                      Feature Structure                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Presentation Layer                     │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐  │   │
│  │  │  Pages  │  │  BLoCs  │  │ Widgets │  │ Adapters │  │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └──────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                       Data Layer                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐   │   │
│  │  │ Repositories │  │    Models    │  │ DataSources │   │   │
│  │  │    (Impl)    │  │              │  │             │   │   │
│  │  └──────────────┘  └──────────────┘  └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Domain Layer                         │   │
│  │  ┌──────────┐  ┌──────────────┐  ┌─────────────────┐   │   │
│  │  │ Entities │  │ Repositories │  │    Use Cases    │   │   │
│  │  │          │  │ (Interfaces) │  │                 │   │   │
│  │  └──────────┘  └──────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Feature-Based Organization
```
src/features/
├── core/           # Shared components
├── logging/        # Main logging functionality
└── devtools_extension/  # DevTools integration
```

### 2. Clean Architecture Layers (per feature)
- **Domain**: Pure business logic, no external dependencies
- **Data**: Implementation details, external services
- **Presentation**: UI components and state management

### 3. Atomic Design (UI Components)
```
presentation/widgets/
├── atoms/      # Basic components (buttons, badges)
├── molecules/  # Combinations (log entry, headers)
└── organisms/  # Complex sections (filter bar, stats)
```

## Dependency Flow

```
External World
     ↓
Presentation Layer (Flutter Widgets, BLoCs)
     ↓
Data Layer (Repositories, Models, DataSources)
     ↓
Domain Layer (Entities, Use Cases, Interfaces)
```

## Benefits

1. **Modularity**: Features are self-contained
2. **Scalability**: Easy to add new features
3. **Testability**: Each layer can be tested independently
4. **Maintainability**: Clear separation of concerns
5. **Team Collaboration**: Teams can work on features independently

## Example: Adding a New Feature

```dart
// 1. Create feature directory
features/analytics/
  ├── domain/
  │   ├── entities/
  │   ├── repositories/
  │   └── usecases/
  ├── data/
  │   ├── models/
  │   ├── repositories/
  │   └── datasources/
  ├── presentation/
  │   ├── pages/
  │   ├── blocs/
  │   └── widgets/
  └── analytics.dart  // Barrel file

// 2. Define domain entities
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  // ...
}

// 3. Create repository interface
abstract class AnalyticsRepository {
  Future<void> trackEvent(AnalyticsEvent event);
}

// 4. Implement data layer
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  // Implementation
}

// 5. Add to main exports if public
export 'src/features/analytics/analytics.dart';
```