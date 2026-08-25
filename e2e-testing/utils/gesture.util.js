const logger = require('../core/logger.util');

class GestureUtil {
  static async tap(driver, element) {
    logger.info('Executing Gesture: Tap');
    if (driver.isMock) return true;
    if (typeof element === 'string') {
      const el = await driver.$(element);
      await el.click();
    } else {
      await element.click();
    }
  }

  static async doubleTap(driver, element) {
    logger.info('Executing Gesture: Double Tap');
    if (driver.isMock) return true;
    const el = typeof element === 'string' ? await driver.$(element) : element;
    const location = await el.getLocation();
    const size = await el.getSize();
    const x = location.x + size.width / 2;
    const y = location.y + size.height / 2;

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x, y },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerUp', button: 0 },
          { type: 'pause', duration: 100 },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async longPress(driver, element, durationMs = 1500) {
    logger.info(`Executing Gesture: Long Press (${durationMs}ms)`);
    if (driver.isMock) return true;
    const el = typeof element === 'string' ? await driver.$(element) : element;
    const location = await el.getLocation();
    const size = await el.getSize();
    const x = location.x + size.width / 2;
    const y = location.y + size.height / 2;

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x, y },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: durationMs },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async scroll(driver, startY = 800, endY = 200, startX = 500) {
    logger.info(`Executing Gesture: Scroll (${startY} -> ${endY})`);
    if (driver.isMock) return true;
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: startX, y: startY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 600, x: startX, y: endY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async swipe(driver, direction = 'LEFT') {
    logger.info(`Executing Gesture: Swipe ${direction}`);
    if (driver.isMock) return true;
    let startX = 800, endX = 200, startY = 500, endY = 500;

    if (direction.toUpperCase() === 'RIGHT') {
      startX = 200; endX = 800;
    } else if (direction.toUpperCase() === 'UP') {
      startX = 500; endX = 500; startY = 800; endY = 200;
    } else if (direction.toUpperCase() === 'DOWN') {
      startX = 500; endX = 500; startY = 200; endY = 800;
    }

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: startX, y: startY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 400, x: endX, y: endY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async dragAndDrop(driver, sourceElement, targetElement) {
    logger.info('Executing Gesture: Drag and Drop');
    if (driver.isMock) return true;
    const sourceEl = typeof sourceElement === 'string' ? await driver.$(sourceElement) : sourceElement;
    const targetEl = typeof targetElement === 'string' ? await driver.$(targetElement) : targetElement;

    const sourceLoc = await sourceEl.getLocation();
    const sourceSize = await sourceEl.getSize();
    const targetLoc = await targetEl.getLocation();
    const targetSize = await targetEl.getSize();

    const startX = sourceLoc.x + sourceSize.width / 2;
    const startY = sourceLoc.y + sourceSize.height / 2;
    const endX = targetLoc.x + targetSize.width / 2;
    const endY = targetLoc.y + targetSize.height / 2;

    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: startX, y: startY },
          { type: 'pointerDown', button: 0 },
          { type: 'pause', duration: 500 },
          { type: 'pointerMove', duration: 1000, x: endX, y: endY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async pinch(driver, centerX = 500, centerY = 500, distance = 200) {
    logger.info('Executing Gesture: Pinch');
    if (driver.isMock) return true;
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - distance, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 500, x: centerX - 20, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + distance, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 500, x: centerX + 20, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }

  static async zoom(driver, centerX = 500, centerY = 500, distance = 50) {
    logger.info('Executing Gesture: Zoom');
    if (driver.isMock) return true;
    await driver.performActions([
      {
        type: 'pointer',
        id: 'finger1',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX - distance, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 500, x: centerX - 200, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      },
      {
        type: 'pointer',
        id: 'finger2',
        parameters: { pointerType: 'touch' },
        actions: [
          { type: 'pointerMove', duration: 0, x: centerX + distance, y: centerY },
          { type: 'pointerDown', button: 0 },
          { type: 'pointerMove', duration: 500, x: centerX + 200, y: centerY },
          { type: 'pointerUp', button: 0 }
        ]
      }
    ]);
  }
}

module.exports = GestureUtil;
