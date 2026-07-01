**Firebase Analytics \& Crashlytics Setup:**


-->Firebase Integration:

1. Download and integrate the Godotx Firebase plugin into the project.
2. Enable the plugin through Project Settings and add the Firebase configuration file (google-services.json).
3. Configure Firebase Analytics to track custom game events and user interactions.
4. Configure Firebase Crashlytics to monitor and report application crashes.
5. Create a Firebase manager script to handle Analytics and Crashlytics functionality.
6. Add the Firebase manager as an AutoLoad (Singleton) for global access across the project.
7. Integrate event logging and crash reporting into the game workflow for monitoring player activity and application stability.





**AdMob Integration Setup:**



-->AdMob Integration

1. Add the Android AdMob Plugin and iOS AdMob Plugin to the project.
2. Enable the plugins in Project Settings.
3. Configure AdMob App IDs for Android and iOS.
4. Configure Banner, Interstitial, and Rewarded Ad Unit IDs.
5. Create an AdMob manager script.
6. Add the AdMob manager script as an AutoLoad (Singleton).
7. Initialize AdMob when the game starts.
8. Test ad integration using AdMob test IDs.





**Meta SDK Integration Setup:**



-->Meta SDK Integration

1. Add the Meta SDK plugin to the Android project.
2. Configure the required Meta SDK settings and dependencies.
3. Update the Android build.gradle file with the required configurations.
4. Configure the Android keystore details for signed builds.
5. Initialize the Meta SDK when the application starts.
6. Create a Meta SDK manager script for handling events.
7. Add the Meta SDK manager script as an AutoLoad (Singleton).
8. Verify event reporting through the Meta Events Manager.



