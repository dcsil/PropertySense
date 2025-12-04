# PropertySense

![Team Logo](./propertysense_logo.png)

#### Team Slack Channel: #team-propertysense>

PropertySense is a company founded in the Property Insurance industry. PropertySense aims to provide AI risk analysis and valuation for insurance companies, brokers, inspectors and more.

Table of Contents
---

- [People](./team/)
- [Product & Research](./product_research/)
    - [Market](./product_research/market.md)
    - [Roadmap](./product_research/roadmap.md)

# Development

## Requirements
- [Flutter](https://docs.flutter.dev/get-started/quick) and relevant requirements (such as xcode-tools)
- [Python](https://www.python.org/downloads/)
- [IOS Simulator/Xcode](https://developer.apple.com/xcode/) if you want to run the simulator

## Setup
1. Clone the [repo](https://github.com/dcsil/PropertySense)
2. In the `object_detect_test` is the actual flutter project. For developing purposes, we suggest you open that directory (rather than the top level dir) in your preferred editor.
3. Install dependencies with `flutter pub get`
4. You can now run the flutter app with `flutter run`. Note that this will automatically run the `main.dart` file, and automatically select the device which you would like to run the flutter app. You can specify this using the `-d` flag.
5. If you are on a mac, we suggest that you use the IOS simulator that comes with XCode. Run `open -a simulator` to run an simulation instance, and then specify this device when running the flutter app.

## Codegen for unit tests
You can generate the classes required for tests using `flutter pub run build_runner build`

## Model Fine-tuning and running the Python backend

# Contributing
## Architecture
Following Flutter standards, the dart files containing the app logic is inside the `lib` directory.

We structure the app using an [MVVM architecture](https://docs.flutter.dev/app-architecture/guide).

### Data Layer
You may find repositories and services(we have none) in `/data`.
For the general interfaces of the data layer, we've made it easy for you to find the methods in [`repositories.dart`](./object_detect_test/lib/data/repos/repositories.dart). This will give you a high level overview of the business logic of the data sources.

The implementations of these repositories can be found in the relevant subdirectories. You may notice some repositories have both local and remote implementations. This is because originally, we made 2 entrypoints `main.dart` and `main_local.dart` where the latter was supposed to be a purely local instance of the app. We suggest that you look at the remote implementations only, as the local implementations weren't used in practice.

### UI Layer
You can find [widgets](https://docs.flutter.dev/app-architecture/case-study/ui-layer#define-a-view-model) and [viewModels](https://docs.flutter.dev/app-architecture/case-study/ui-layer#define-a-view-model) inside the `/ui` directory.

ViewModels and Screens/Widgets/Views have a 1-to-1 mapping. We aimed to have screens be [`StatelessWidgets`](https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html)(although this didn't always end up happening in practice).

Thus, the business logic for each screen lives in the corresponding viewmodel. You can get a sense of which repositories are dependency injected into the viewmodel when they are instantiated: 
```
ChangeNotifierProvider<RegistrationViewModel>(
    create: (context) => RegistrationViewModel(
    context.read<AuthRepository>(),
    context.read<UserRepository>(),
    ),
```
Certain viewmodels are instantiated at the top level of the [Provider](https://pub.dev/packages/provider) tree, some are instantiated when the screen is called (so we don't use resources on them while we're not at the screen). Please be wary of this when looking for them in `main.dart`

NOTE: For certain screens such as a single step in the registration flow, it doesn't not have it's own viewmodel. The business logic for the whole registration flow is aggregated into a single viewmodel.

### Domain Models
We define our business entities in `/domain`. They mostly contain firestore conversion methods.
We don't always store data in our firestore the same way they look in the domain models.
From [`user_model.dart`](https://github.com/dcsil/PropertySense/blob/1eb03bee4a0b8ff75c9c00e8872949c2cc61f96b/object_detect_test/lib/domain/models/user_model.dart#L15)
```
  // Assumes that address will always have a corresponding placemark (using geocoding package)
  // We're basically praying that the geocoding PlacemarkFromCoordinates will always return a valid placemark.(Not sure if this is true).
  // Only store geopoint in firestore, but we'll have placemark in memory for easy access to address components.
  final Location location; 
```

### Utils
In `/utils` we store helpers such as a Result type and Toaster which help display toasts in the UI.

### Python Backend
Separate from the Flutter app, we have the `/backend` directory, which contains Python code to fine tune and deploy YOLO models for use in the flutter app. 

The data for fine tuning the YOLO model is the [Building Defects Detection Dataset](https://github.com/Praveenkottari/BD3-Dataset), which can be downloaded from the linked repo. We use the `augmented` folder inside the dataset, renamed to `data` and placed under `backend`. 

The dataset is not required for model inference to run. It is only required for fine tuning and deploying a new YOLO model.


# Deployment
To deploy the app, just run the [Build and Distribute Workflow](https://github.com/dcsil/PropertySense/actions/workflows/firebase-ios-deploy.yaml).
Seriously, that's it!

This will build the flutter ipa, and then deploy it to the app store connect repository which looks something like this:
![alt text](appstorebuilds.png)

From there, we can allow specific Testflight groups access to this build, and all testers in a group will be notified.
![alt text](testflight.png)

In theory, we could also submit the app for review for the App Store. However, we have not done this for this project.

# Testing

### Running Tests

Run all unit tests:
```bash
cd object_detect_test
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

Run a specific test file:
```bash
flutter test test/ui/viewmodels/login_viewmodel_test.dart
```

### Test Structure

- **Unit Tests**: Located in `test/` directory, organized to mirror `lib/` structure
- **Integration Tests**: Located in `integration_test/` directory

### Code Coverage

Coverage reports are generated automatically in CI/CD. To generate locally:

```bash
flutter test --coverage
# Coverage data is written to coverage/lcov.info
```

### Test Dependencies

- `flutter_test` - Core testing framework
- `mockito` - Mocking framework
- `build_runner` - Code generation for mocks

To generate mock classes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

# Note for CSC491 assessors
If you like to avoid the setup process that involves the XCode + simulator process. Please feel free to message @SunnyK in the discord. I will add you to the testflight group so that you can download the app on your phones. This is the easiest method to actually get to use the app(for what's it's worth) on a real device.

Other methods such as IPA sideloading unfortunately will require me to add your phone's device IDs to the provisioning profiles, or require an Enterprise app store connect account. 

Thank you!!!
