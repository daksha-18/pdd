const path = require('path');
require('dotenv').config();

module.exports = {
  host: process.env.APPIUM_HOST || '127.0.0.1',
  port: parseInt(process.env.APPIUM_PORT, 10) || 4723,
  path: '/',

  // APK and App Configuration
  apkPath: process.env.APK_PATH || path.join(__dirname, '../app/app-release.apk'),
  appPackage: process.env.APP_PACKAGE || 'com.company.app',
  appActivity: process.env.APP_ACTIVITY || 'com.company.app.MainActivity',

  // Default Device Capabilities
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2', // UiAutomator2 fallback or Flutter/React-Native driver
    'appium:deviceName': process.env.DEVICE_NAME || 'Android Emulator',
    'appium:platformVersion': process.env.ANDROID_VERSION || '13.0',
    'appium:app': process.env.APK_PATH || path.join(__dirname, '../app/app-release.apk'),
    'appium:appPackage': process.env.APP_PACKAGE || 'com.company.app',
    'appium:appActivity': process.env.APP_ACTIVITY || 'com.company.app.MainActivity',
    'appium:autoGrantPermissions': true,
    'appium:noReset': false,
    'appium:fullReset': false,
    'appium:newCommandTimeout': 300,
    'appium:ensureWebviewsHavePages': true,
    'appium:nativeWebScreenshot': true,
    'appium:connectHardwareKeyboard': true
  },

  // Device Matrix Support (Android 10 - 15)
  supportedVersions: ['10.0', '11.0', '12.0', '13.0', '14.0', '15.0'],
  
  // Timeout Configurations
  implicitWaitMs: 10000,
  explicitWaitMs: 15000,
  pageLoadWaitMs: 30000
};
