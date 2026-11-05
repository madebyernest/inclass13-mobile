# In-Class Activity 13: Flutter + Firebase Authentication

Email/password registration, sign-in, sign-out, and a profile screen that is reachable only while signed in.
Shows the signed-in email and lets the user update their password.

## Structure

| File | Role |
|------|------|
| `lib/services/auth_service.dart` | All FirebaseAuth calls, plus `authErrorMessage()` mapping error codes to safe text |
| `lib/main.dart` | Initializes Firebase, then a `StreamBuilder` on `authStateChanges()` picks the screen |
| `lib/screens/auth_screen.dart` | Register / sign-in form with validation, loading state, safe errors |
| `lib/screens/profile_screen.dart` | Email, password update (with reauth retry), sign-out |

Authentication proves *who* the user is. Routing on auth state is a simple authorization check (signed-in users see the profile). Per-user data would need Firestore rules; that optional extension is not implemented.

## Setup

1. Firebase Console: create a project, enable **Authentication -> Sign-in method -> Email/Password**.
2. `flutter create .` (if starting fresh), then copy `lib/` over and add dependencies:
   `flutter pub add firebase_core firebase_auth`
3. `dart pub global activate flutterfire_cli`, then `flutterfire configure` (select Android). This generates `lib/firebase_options.dart`.
4. Add `<uses-permission android:name="android.permission.INTERNET" />` inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`.
5. `flutter pub get && flutter run`

Do not commit signing keys or passwords.

## Build the APK

`flutter build apk --release` -> `build/app/outputs/flutter-apk/app-release.apk`. Install it and repeat the tests below.

## Test plan (record outcome + screenshot for each)

| # | Action | Expected |
|---|--------|----------|
| 1 | Register with a valid email and 6+ char password | Lands on profile showing that email; user appears in Console -> Authentication -> Users |
| 2 | Register with `abc` as the email | Inline "valid email" message; no request sent |
| 3 | Register with a 4-char password | Inline "at least 6 characters" message |
| 4 | Register with an already-used email | "An account already exists..." message |
| 5 | Sign out | Returns to sign-in screen |
| 6 | Sign in with wrong password | "Email or password is incorrect." (no raw exception) |
| 7 | Sign in with correct credentials | Profile shown |
| 8 | Kill and reopen the app while signed in | Profile shown without signing in (session restored) |
| 9 | Update password to a new 6+ char value | "Password updated." |
| 10 | Sign out, sign in with new password | Succeeds |
| 11 | Sign in with old password | Fails with the incorrect-credentials message |
| 12 | Submit while request is in flight | Button disabled, spinner shown |
| 13 | Requires-recent-login (only if Firebase triggers it) | Dialog asks for current password, reauthenticates, retries. If it does not occur, label this as an untested plan in your write-up |