# Enterprise E2E Test Automation Framework (Appium 2.x, API, Load, & Vulnerability Testing)

This folder contains the automated test suite for the **HostelCare** application, providing:
- **300 Appium UI / E2E Test Cases**: React Native & Flutter widget locators, gestures, role-based workflows.
- **300 API Test Cases**: Auth, Admin, Complaints, Analytics, Staff, Users, Chatbot.
- **300 Load Test Scenarios**: Virtual users, RPS targets, response latency benchmarks.
- **300 Security & Vulnerability Test Scenarios**: OWASP Top 10, SQL/NoSQL Injection, XSS, JWT tampering, IDOR, CORS.
- **Multi-Tab Excel Generator (`ExcelJS`)**: Automatically creates `React_native_E2E_Report.xlsx` with 7 formatted worksheets.
- **Mochawesome HTML Reporting**: Visual charts and execution breakdown.
- **Smart AI Testing Module**: Dynamic screen analyzer and scenario expander.
- **GitHub Actions Integration**: Automated CI pipeline running emulator and uploading reports.

## Project Structure

```
e2e-testing/
├── config/
│   └── appium.config.js          # Appium & APK capabilities
├── core/
│   ├── driver.factory.js         # Session & driver manager
│   ├── logger.util.js            # Winston logger
│   └── failure.handler.js        # Screenshot, logcat & widget tree capture
├── pages/
│   ├── base.page.js              # Page object base with widget finders
│   ├── login.page.js             # Login screen page object
│   └── app_pages.js              # Dashboard, complaint, admin, staff page objects
├── test/
│   ├── appium_300.spec.js        # 300 Appium E2E tests
│   ├── api_300.spec.js           # 300 API tests
│   ├── load_300.spec.js          # 300 Load test scenarios
│   └── vulnerability_300.spec.js # 300 Security test scenarios
├── utils/
│   ├── gesture.util.js           # Tap, double tap, long press, scroll, swipe, drag, pinch, zoom
│   ├── excel.reporter.js         # Multi-tab Excel report generator
│   └── smart-ai-tester.js        # AI screen inspector & test expander
├── run-all-tests.js              # Master test runner
└── package.json                  # Dependencies
```

## Running Tests Locally

```bash
# Install dependencies
npm install

# Run all 1,200 test cases & generate Excel report
npm test

# Run individual suites
npm run test:appium
npm run test:api
npm run test:load
npm run test:vulnerability

# Run AI discovery module
npm run ai-discover
```
