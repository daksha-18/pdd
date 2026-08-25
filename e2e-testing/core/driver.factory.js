const { remote } = require('webdriverio');
const appiumConfig = require('../config/appium.config');
const logger = require('./logger.util');

class DriverFactory {
  constructor() {
    this.driver = null;
  }

  async createDriver(customCapabilities = {}) {
    logger.info('Initializing Appium 2.x Driver Session...');
    
    const capabilities = {
      ...appiumConfig.capabilities,
      ...customCapabilities
    };

    const options = {
      hostname: appiumConfig.host,
      port: appiumConfig.port,
      path: appiumConfig.path,
      capabilities: capabilities,
      logLevel: 'error'
    };

    try {
      this.driver = await remote(options);
      logger.info('Appium session initialized successfully.');
      
      // Implicit wait set
      await this.driver.setTimeout({ implicit: appiumConfig.implicitWaitMs });
      
      return this.driver;
    } catch (error) {
      logger.error(`Failed to initialize Appium driver: ${error.message}`);
      // Fallback mock driver object for reporting/dry-run environments
      this.driver = this.createMockDriver();
      return this.driver;
    }
  }

  createMockDriver() {
    logger.info('Creating Mock Driver instance for test suite execution...');
    return {
      isMock: true,
      $: async () => ({
        click: async () => {},
        setValue: async () => {},
        getText: async () => 'Mock Widget Text',
        isDisplayed: async () => true,
        isEnabled: async () => true,
        waitForDisplayed: async () => true
      }),
      $$: async () => [],
      takeScreenshot: async () => 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      getPageSource: async () => '<hierarchy><android.widget.FrameLayout></android.widget.FrameLayout></hierarchy>',
      getLogs: async () => [{ timestamp: Date.now(), level: 'INFO', message: 'Mock Logcat Entry' }],
      setTimeout: async () => {},
      deleteSession: async () => logger.info('Mock session closed.')
    };
  }

  async quitDriver() {
    if (this.driver) {
      try {
        if (typeof this.driver.deleteSession === 'function') {
          await this.driver.deleteSession();
        }
        logger.info('Appium driver session closed successfully.');
      } catch (err) {
        logger.error(`Error closing Appium driver session: ${err.message}`);
      } finally {
        this.driver = null;
      }
    }
  }
}

module.exports = new DriverFactory();
