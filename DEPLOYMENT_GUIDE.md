# Hướng dẫn Deploy lên Google Play Store & App Store

## 📱 Android (Google Play Store)

### 1. Kiểm tra cấu hình đã sẵn sàng

✅ **Đã hoàn thành:**
- Package name: `com.coup.boardgame`
- Keystore: `android/app/coup_boardgame.keystore`
- Signing config: `android/key.properties`
- Version: 1.0.1 (versionCode: 2)

### 2. Build Release AAB (Android App Bundle)

```bash
# Build AAB file
fvm flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

Hoặc build APK:
```bash
fvm flutter build apk --release
```

### 3. Test Release Build

Trước khi upload, hãy test trên thiết bị thật:

```bash
# Connect thiết bị Android qua USB (bật USB Debugging)
fvm flutter install --release
```

Hoặc copy APK vào điện thoại:
```bash
# Với APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4. Tạo Store Listing trên Google Play Console

1. Truy cập [Google Play Console](https://play.google.com/console)
2. Tạo ứng dụng mới
3. Điền thông tin:
   - **App name**: Coup Boardgame
   - **Short description**: Trò chơi Coup - Trò chơi đổ bác, phản bội và chiến lược
   - **Full description**: Mô tả chi tiết về game
   - **Graphics**: Icon (512x512), Feature graphic (1024x500), Screenshots (min 2)
   - **Category**: Board
   - **Content rating**: Điền thông tin và hoàn thành questionnaire
   - **Privacy policy**: URL đến privacy policy (bắt buộc)

### 5. Upload AAB

1. Vào **Release > Production**
2. Tạo new release
3. Upload file `app-release.aab`
4. Điền release notes
5. **QUAN TRỌNG**: Kích hoạt **Google Play App Signing** (nếu chưa bật)
   - Play Console sẽ quản lý key signing cho bạn
   - Upload keystore upload key (có thể dùng keystore hiện tại)

### 6. Submit for Review

- Sau khi upload, review và submit
- Thời gian review: vài giờ đến vài ngày

---

## 🍎 iOS (App Store)

### 1. Kiểm tra cấu hình

✅ **Đã hoàn thành:**
- Bundle ID: `com.coup.boardgame`
- Version: 1.0.1
- Firebase config đã cập nhật

### 2. Cấu hình Xcode

1. Mở project iOS:
```bash
open ios/Runner.xcworkspace
```

2. Trong Xcode:
   - Chọn Runner target
   - General tab:
     - **Bundle Identifier**: `com.coup.boardgame`
     - **Version**: 1.0.1
     - **Build**: 2
   - Signing & Capabilities:
     - Chọn Team (tài khoản Apple Developer)
     - Enable **Automatically manage signing**

### 3. Build Archive

```bash
# Clean build
fvm flutter clean

# Build iOS release
fvm flutter build ios --release

# Hoặc dùng Xcode:
# Product > Archive
```

### 4. Upload lên App Store Connect

1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. Tạo app mới với Bundle ID `com.coup.boardgame`
3. Điền thông tin:
   - App name, subtitle, description
   - Keywords
   - Screenshots (cần nhiều size)
   - Privacy policy URL
   - Support URL
   - Category: Games > Board

4. Upload binary:
   - Dùng Xcode: Organizer > Distribute App > App Store Connect
   - Hoặc dùng Transporter (Mac App Store)

5. Fill thông tin trước khi submit:
   - Export compliance
   - Content rights
   - Age rating

6. Submit for review

---

## 🔧 Firebase Setup (Quan trọng)

Vì package name đã đổi, bạn cần:

### Tùy chọn 1: Tạo Firebase project mới (Recommended)
1. Vào [Firebase Console](https://console.firebase.google.com)
2. Tạo project mới: `coup-boardgame`
3. Thêm Android app với package `com.coup.boardgame`
4. Tải `google-services.json` mới và thay thế file cũ
5. Thêm iOS app với bundle ID `com.coup.boardgame`
6. Tải `GoogleService-Info.plist` mới và thay thế

### Tùy chọn 2: Thêm app vào Firebase project cũ
1. Vào Firebase Console > Project Settings
2. Thêm Android app với package mới
3. Thêm iOS app với bundle ID mới
4. Tải config files mới

---

## 📋 Checklist trước khi Deploy

- [ ] Package name đã đúng (Android & iOS)
- [ ] Keystore đã tạo và lưu an toàn
- [ ] Version code/name đã cập nhật
- [ ] Firebase config files đã cập nhật với package mới
- [ ] Test release build trên thiết bị thật
- [ ] Store assets đã sẵn sàng (icon, screenshots, descriptions)
- [ ] Privacy policy URL
- [ ] Tài khoản Developer (Google Play $25, Apple $99/year)

---

## 🚀 Build & Deploy Commands

```bash
# Android AAB
fvm flutter build appbundle --release

# Android APK
fvm flutter build apk --release

# iOS (cần Mac)
fvm flutter build ios --release

# Web (nếu cần)
fvm flutter build web --release
```

---

## ⚠️ Lưu ý quan trọng

1. **Keystore**: Giữ keystore an toàn, backup ở nhiều nơi. Nếu mất, không thể update app.
2. **Version code**: Phải tăng mỗi lần upload lên Play Store.
3. **Firebase**: Nếu dùng Firebase Auth, cần cấu hình OAuth redirect domains.
4. **App Store**: Cần tài khoản Apple Developer ($99/năm).
5. **Google Play**: Cần tài khoản Developer ($25 một lần).

---

## 🆘 Cần hỗ trợ?

Nếu gặp lỗi build:
```bash
# Clean và rebuild
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --release
```

Lỗi signing: Kiểm tra `android/key.properties` path và password.
