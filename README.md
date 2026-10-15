# Dubai 777-style starter (Flutter + Firebase + Web Admin)

This is a clean starter project inspired by the feature categories visible in the supplied APK. It is **not** the original app source code and does not include real-money gaming or payment processing.

## Included
- Flutter Android client: email/password login/register, home, demo prediction screen, wallet/passbook, referral code, support ticket
- Firebase Authentication + Cloud Firestore + callable Cloud Functions
- Web Admin Panel starter for reviewing wallet requests
- Firestore rules and setup instructions

## Prerequisites
- Flutter stable, Android Studio, Android SDK, Node.js LTS, Firebase CLI
- A Firebase project you control
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## 1. Create the Flutter shell
From the directory containing this folder:
```bash
flutter create dubai777_app
cd dubai777_app
```
Copy `client/lib/main.dart` into `dubai777_app/lib/main.dart`.
Replace `pubspec.yaml` with the provided `client/pubspec.yaml` or merge its dependencies.
Then run:
```bash
flutter pub get
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
`flutterfire configure` generates `lib/firebase_options.dart`. The supplied app imports that generated file.

## 2. Set up Firebase
1. Create a Firebase project in the Firebase Console.
2. Enable **Authentication > Email/Password**.
3. Create a Firestore database in test mode temporarily, then deploy the rules below.
4. Enable Cloud Functions and link billing if required by Firebase for your region/project.
5. Install the Firebase CLI: `npm install -g firebase-tools`
6. In this project root:
```bash
firebase login
firebase use --add
```
Choose your Firebase project and give it an alias such as `default`.
Copy `backend/firestore.rules` to `firestore.rules`.
Copy `backend/firebase.json` to the project root.
Copy `backend/functions` to the project root as `functions`.
Then:
```bash
cd functions
npm install
cd ..
firebase deploy --only firestore:rules,functions
```

## 3. Set up the Admin Panel
1. Open `admin/index.html`.
2. Replace the `firebaseConfig` placeholder with your Firebase Web App configuration from Firebase Console > Project settings.
3. Serve it locally (do not open as `file://`):
```bash
cd admin
python -m http.server 8080
```
Open `http://localhost:8080`.
4. In Firebase Console, create an admin user's account, then set its custom claim using the Admin SDK from a trusted server environment. Example (run only on a trusted machine with service-account credentials; never put a service-account key in a web page):
```js
await getAuth().setCustomUserClaims("ADMIN_UID_HERE", { admin: true });
```
Sign out and sign in again after the claim is set. The admin panel checks this claim. Firestore rules and Cloud Functions also enforce admin claims.

## 4. Run Android
In the Flutter project:
```bash
flutter run
flutter build apk --debug
flutter build apk --release
```
APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Important implementation notes
- Wallet balance is not client-writable. The client can only create a request through a callable function.
- This starter's request approval function only records a review decision; it intentionally does **not** credit or debit balances. Integrate a licensed payment provider and a reviewed ledger design before any real money flow.
- Prediction entries are demonstration-only and are not bets.
- Never store payment secrets, service-account keys, or admin credentials in the client app or web bundle.
- Before launch, add App Check, rate limiting, monitoring, privacy policy, terms, data deletion, age/legal checks, and security review.
