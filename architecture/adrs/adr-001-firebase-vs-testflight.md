## ADR 001: Firebase App Distribution vs App Store Connect + TestFlight

## Context
For distributing our test builds, we must decide on a beta distribution service that works for users on IOS.

### Options

#### Firebase
[Firebase](https://firebase.google.com/docs/app-distribution) integrates well with our existing Firebase backend but is not strongly linked to App Store Connect and the App Review process.

##### Pros
- Easy to use/setup with CI.
- Integrates with existing Firebase project that we're already using for Firebase Auth and Firestore.
- Cross-platform
- No Apple Developer account required (Can use Firebase project collaborators)

##### Cons
- Manual provisioning profiles required
- Installation for testers is more clunky vs Testflight
- Testflight is Apple native and vetted. No one on team has used firebase app distribution before
- Creates stronger coupling with Firebase (What if we want to move away from firebase in the future?)

#### TestFlight
[TestFlight](https://developer.apple.com/testflight/) is a more cumbersome process to setup due to Apple's rigorous security protocols and will not scale well if we decide to deploy to Android as well.

##### Pros
- Apple Native (Apple Store Connect API Compatible)
- Easier installation process for testers
- Experience much closer to app store (shares package storage with app store)
- Build is already uploaded for app store review

##### Cons
- IOS only
- Internal Testing is limited
- 90 day expiration
- A lot more annoying to set up CI + fastlane is annoying to set up.

## Decision: TestFlight

## Status
Closed. ✅ 

CI has been implemented (and merged to master) with IPA going to straight to App Store Connect/TestFlight.

## Consequences
No Firebase App Distribution instance was initialized for Firebase project.
App Store Connect API key created and installed repo secrets.
App Store Connect Provisioning Profile and Certificate has also been set up and added to repo secrets.
