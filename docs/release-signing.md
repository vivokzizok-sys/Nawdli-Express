# Android Release Signing

Veloce Express release APKs must be signed with the same keystore every time.
If this keystore or its passwords are lost, installed users cannot receive normal updates.

## Create the local keystore

Run this from the project root in PowerShell:

```powershell
.\tools\create_release_keystore.ps1
```

It creates:

```text
android/app/veloce-express-release-key.jks
android/key.properties
```

Both files are ignored by Git and must stay private.

## Build signed APKs locally

```powershell
C:\flutter\bin\flutter.bat build apk --release --split-per-abi --tree-shake-icons
```

The output is in:

```text
build/app/outputs/flutter-apk/
```

## GitHub Actions signed builds

Add these GitHub repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Create `ANDROID_KEYSTORE_BASE64` locally:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\veloce-express-release-key.jks")) | Set-Content keystore_base64.txt
```

Copy the content of `keystore_base64.txt` into the GitHub secret.
Do not commit `keystore_base64.txt`.
