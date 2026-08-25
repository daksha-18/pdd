const logger = require('../core/logger.util');

class BasePage {
  constructor(driver) {
    this.driver = driver;
  }

  // React Native / Flutter Specific Locator Helpers
  async findByValueKey(key) {
    if (this.driver.isMock) return this.driver.$(`[key="${key}"]`);
    return await this.driver.$(`~${key}`);
  }

  async findByText(text) {
    if (this.driver.isMock) return this.driver.$(`[text="${text}"]`);
    return await this.driver.$(`//*[@text="${text}" or @content-desc="${text}"]`);
  }

  async findBySemanticsLabel(label) {
    if (this.driver.isMock) return this.driver.$(`[semantics="${label}"]`);
    return await this.driver.$(`~${label}`);
  }

  async findByAccessibilityId(id) {
    if (this.driver.isMock) return this.driver.$(`[accessibility-id="${id}"]`);
    return await this.driver.$(`~${id}`);
  }

  // Common UI Widget Finders
  async getElevatedButton(text) {
    return await this.findByText(text);
  }

  async getTextField(valueKeyOrHint) {
    if (this.driver.isMock) return this.driver.$(`[field="${valueKeyOrHint}"]`);
    return await this.driver.$(`//*[@class="android.widget.EditText" and (@text="${valueKeyOrHint}" or @content-desc="${valueKeyOrHint}")]`);
  }

  async getDropdownButton(valueKey) {
    return await this.findByValueKey(valueKey);
  }

  async getCheckbox(valueKey) {
    return await this.findByValueKey(valueKey);
  }

  async getRadio(valueKey) {
    return await this.findByValueKey(valueKey);
  }

  async getSwitch(valueKey) {
    return await this.findByValueKey(valueKey);
  }

  async getDialog() {
    if (this.driver.isMock) return this.driver.$('[dialog]');
    return await this.driver.$('//*[@class="android.app.Dialog" or @resource-id="android:id/parentPanel"]');
  }

  async getSnackbar() {
    if (this.driver.isMock) return this.driver.$('[snackbar]');
    return await this.driver.$('//*[@class="android.widget.Toast" or contains(@resource-id, "snackbar")]');
  }

  async getValidationMessage() {
    if (this.driver.isMock) return 'Field is required';
    const snackbar = await this.getSnackbar();
    if (await snackbar.isDisplayed()) {
      return await snackbar.getText();
    }
    const errText = await this.driver.$('//*[@class="android.widget.TextView" and contains(@text, "required") or contains(@text, "invalid") or contains(@text, "Error")]');
    return await errText.getText();
  }
}

module.exports = BasePage;
