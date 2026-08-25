const fs = require('fs');
const path = require('path');
const logger = require('./logger.util');

class FailureHandler {
  static async handleFailure(driver, testTitle, error) {
    const failureDir = path.join(__dirname, '../reports/failures');
    if (!fs.existsSync(failureDir)) {
      fs.mkdirSync(failureDir, { recursive: true });
    }

    const sanitizedTitle = testTitle.replace(/[^a-zA-Z0-9_-]/g, '_');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const baseFilename = `${sanitizedTitle}_${timestamp}`;

    const failureRecord = {
      testName: testTitle,
      timestamp: new Date().toISOString(),
      error: error.message || error.toString(),
      stackTrace: error.stack || 'No stack trace available',
      screenshotPath: null,
      deviceLogsPath: null,
      widgetTreePath: null,
      screenName: 'Unknown'
    };

    if (driver) {
      try {
        // 1. Capture Screenshot
        const screenshotPath = path.join(failureDir, `${baseFilename}.png`);
        const screenshotBase64 = await driver.takeScreenshot();
        fs.writeFileSync(screenshotPath, screenshotBase64, 'base64');
        failureRecord.screenshotPath = screenshotPath;
        logger.info(`Failure screenshot saved to: ${screenshotPath}`);
      } catch (err) {
        logger.error(`Failed to capture failure screenshot: ${err.message}`);
      }

      try {
        // 2. Dump Page Source / Widget Tree
        const widgetTreePath = path.join(failureDir, `${baseFilename}_widget_tree.xml`);
        const pageSource = await driver.getPageSource();
        fs.writeFileSync(widgetTreePath, pageSource, 'utf8');
        failureRecord.widgetTreePath = widgetTreePath;
        logger.info(`Failure widget tree saved to: ${widgetTreePath}`);
      } catch (err) {
        logger.error(`Failed to dump widget tree: ${err.message}`);
      }

      try {
        // 3. Get Device Logs
        const logsPath = path.join(failureDir, `${baseFilename}_device.log`);
        let logs = [];
        try {
          logs = await driver.getLogs('logcat');
        } catch (e) {
          logs = [{ message: 'Logcat log retrieval not supported in current session' }];
        }
        const logContent = logs.map(l => `[${l.timestamp || ''}] [${l.level || 'INFO'}] ${l.message}`).join('\n');
        fs.writeFileSync(logsPath, logContent, 'utf8');
        failureRecord.deviceLogsPath = logsPath;
        logger.info(`Device logs dumped to: ${logsPath}`);
      } catch (err) {
        logger.error(`Failed to dump device logs: ${err.message}`);
      }
    }

    // Save Failure JSON summary
    const recordPath = path.join(failureDir, `${baseFilename}_summary.json`);
    fs.writeFileSync(recordPath, JSON.stringify(failureRecord, null, 2), 'utf8');

    return failureRecord;
  }
}

module.exports = FailureHandler;
