# Setup & Configuration Guide

## Prerequisites

1. **Node.js**: Version 18.x or 20.x
2. **Java Development Kit (JDK)**: JDK 17
3. **Android Studio**: Android SDK & Android Virtual Device (AVD) Pixel Emulator (API 30+)
4. **Appium 2.x**:
   ```bash
   npm install -g appium
   appium driver install uiautomator2
   ```

## Environment Variables (.env)

Create a `.env` file in `e2e-testing/` if custom paths/ports are needed:

```env
APPIUM_HOST=127.0.0.1
APPIUM_PORT=4723
APK_PATH=./app/app-release.apk
APP_PACKAGE=com.company.app
APP_ACTIVITY=com.company.app.MainActivity
DEVICE_NAME=Pixel_6_API_33
ANDROID_VERSION=13.0
```

## Reports Generated

After execution, reports are saved in `reports/`:
1. `reports/React_native_E2E_Report.xlsx`: Multi-tab Excel report containing:
   - Summary
   - Appium Test Cases (300)
   - API Test Cases (300)
   - Load Test Cases (300)
   - Vulnerability Test Cases (300)
   - Failed Tests
   - Execution Logs
2. `reports/index.html`: Mochawesome visual HTML report.
3. `reports/failures/`: Contains failure screenshots (`.png`), device logcat (`.log`), widget tree (`.xml`), and summary JSON files.
