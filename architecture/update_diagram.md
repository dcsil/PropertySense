# Architecture Diagram (Updated for final assignment)

## Diagram

![Architecture Diagram](./updated_diagram.png)

## Explanation

<!-- Our architecture is designed as a lightweight backend interacting with a Flutter IOS app running on Google Cloud. The core backend will be a FastAPI container running on Google Cloud Run calling out to the OpenAI API for AI inference, using a lightweight CloudSQL instance for persistent storage such as property data, and google cloud identity platform for auth.  -->
Our architecture consists of a simple Firebase/Flutter application making calls to Firestore for user, offer, and listing data, while calling to OpenStreetMap's public tile servers.

We are using a YOLOv5 for object detection running in the client side, which we fine tuned using Pytorch.

### Frontend: Flutter IOS app

Flutter was chosen because we our team members had previous experience with the framework, and because we cannot use SwiftUI due to one of our team members using a Windows computer. 

In hindsight, flutter was a useful due to the fast iteration speed it gave us, easy state management with `provider`, plus high-level packages provided with batteries included. 
e.g.: 
- [native_flutter_splash_screen](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/pubspec.yaml#L122)
- [flutter_card_swiper](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/ui/views/listing_swipe_screen.dart#L76)
- [cloud_firestore](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/main.dart#L4)
- [location](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/data/repos/location_repository_remote.dart#L4)
- [provider](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/main.dart#L16)

#### OpenStreetMap
To avoid paying for Google's map sdk, we opted to use OpenStreetMap to render out map view. We graciously use the free public tile servers provided by OSM in our application.

[Example Usage](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/ui/views/listing_map_screen.dart#L87)

### Backend: Firebase
Although initially we leaned towards a relational database for our startup, we couldn't deny the ease of integration and flexibility that Firestore provided, with it's realtime capabilities, built-in dart sdk, and emulator libraries.
We use firebase auth and firestore.

[UserRepository](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/data/repos/user/user_repository_local.dart#L4)

[AuthRepository](https://github.com/dcsil/PropertySense/blob/0bef19c49986dab2ba31061e7780ca88e337d49f/object_detect_test/lib/data/repos/auth/auth_repository_remote.dart#L4)

### Training Backend: Pytorch

### DevOps - GitHub + App Store Connect
Used for testing action and deployment action. We are using App Store Connect's API to build the flutter apps and then deploy the builds directly to the App Store Connect repository. This allows us to push our test builds directly to our testers with no additional build process from the developers. We also cache the ipas, so that if we need to download and run them directly, we can access the builds that way as well.

[Successful CI run example](https://github.com/dcsil/PropertySense/actions/runs/19749838240)

## Alignment with Use Cases

This architecture directly supports our Critical User Journeys (CUJs) by ensuring:

1. Clean, familiar UI frameworks along with the Apple iOS ecosystem for easy installation and keeping in line with lightweight, efficient UX.

2. High velocity development, and reactive iteration to cohere to alpha and beta test findings.

3. Secure auth, reliable AI inference, and near-0 downtime by taking advantage of existing cloud and vendor solutions.