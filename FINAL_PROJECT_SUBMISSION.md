# FINAL PROJECT: Software MVP for PropertySense
# 1. Product Overview
# 2. MVP Development Justification
# 3. Functional and Dynamic MVP
# 4. Test Coverage
## Overview

Our project uses a comprehensive testing strategy with both **unit tests** and **integration tests** to ensure code quality and reliability. Tests are organized following Flutter's standard testing conventions.

## CI/CD and Coverage

**Latest passing CI with coverage artifacts:** [View latest CI run](https://github.com/dcsil/PropertySense/actions/workflows/unit-test.yaml)

**Code Coverage:** Coverage is tracked and reported in CI/CD. Current coverage is at **68.3%** line coverage across the application. Coverage reports are generated using `flutter test --coverage` and uploaded as artifacts in GitHub Actions.

## Code Quality & Tooling

**Flutter/Dart Stack:**
- **Testing Framework**: `flutter_test` (Flutter SDK) with `mockito` for mocking dependencies
- **Code Generation**: `build_runner` for generating mock classes from interfaces
- **Integration Testing**: `integration_test` (Flutter SDK) for end-to-end testing

**CI (GitHub Actions):**
- Automated test execution on every pull request and push to `main`
- Coverage generation using `lcov` for line coverage reporting
- HTML coverage reports generated and uploaded as downloadable artifacts

## What We Test

### Data Layer (Repositories)
- **AuthRepository**: Authentication state changes, email/password sign-in, Google/Apple sign-in, sign-out, sign-up, password reset, email verification flows
- **UserRepository**: User document creation, fetching, and state management (covered via ViewModel tests)

### Domain Layer
- **Models**: 
  - `DefectDetection`: Constructor validation, cost calculations (min/max/avg), display name generation, cost range formatting
- **Services**:
  - `PricePredictor`: Single defect prediction, batch prediction, total cost aggregation, confidence-based cost calculations

### UI Layer (ViewModels)
- **LoginViewModel**: Email/password validation, authentication flows, Google/Apple sign-in, password visibility toggling, auth state change handling
- **RegistrationViewModel**: Multi-step registration flow, form validation, step navigation, user type selection, address/identification handling, user document creation
- **EmailSignupViewModel**: Email/password signup, validation, password visibility, auth state management
- **ListingsViewModel**: Listing loading, filtering by status, refresh functionality, error handling
- **ProfileHomeownerViewModel**: Profile updates, homeowner details management, sign-out functionality
- **ProfileContractorViewModel**: Profile updates, contractor details management, listing type filters, radius settings, sign-out functionality

### Integration Tests
- **Login Flow**: Complete authentication flow for both homeowner and contractor user types
- **Navigation**: Screen transitions and routing validation
- **Firebase Integration**: End-to-end testing with Firebase emulator for authentication and Firestore operations

## Running Tests

### Run All Unit Tests

To run all unit tests:

```bash
cd object_detect_test
flutter test
```

### Run Specific Test Files

To run a specific test file:

```bash
flutter test test/ui/viewmodels/login_viewmodel_test.dart
```

### Run Tests with Coverage

To generate code coverage reports:

```bash
flutter test --coverage
```

Coverage data will be written to `coverage/lcov.info`. To view a human-readable summary
You can use a coverage viewer tool or parse the `lcov.info` file directly.

### Run Integration Tests

Integration tests require the Firebase emulator to be running and populated with test data:

```bash
# Start Firebase emulator with test data
firebase emulator:start --import=./emulator_data

# In another terminal, run integration tests
cd object_detect_test
flutter test integration_test/
```

## Test Dependencies

The following packages are used for testing:

- **flutter_test**: Core Flutter testing framework (included with Flutter SDK)
- **mockito**: Mocking framework for creating test doubles
- **build_runner**: Code generation tool for creating mock classes
- **integration_test**: Flutter SDK integration testing framework


# 5. Demo Recording and In Class Live Demo
# 6. Deployment Documentation
# 7. Updated Architecture Diagram
