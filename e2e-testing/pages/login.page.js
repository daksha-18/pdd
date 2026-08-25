const BasePage = require('./base.page');

class LoginPage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async getEmailField() {
    return await this.findByValueKey('email_input');
  }

  async getPasswordField() {
    return await this.findByValueKey('password_input');
  }

  async getRoleDropdown() {
    return await this.findByValueKey('role_dropdown');
  }

  async getLoginButton() {
    return await this.findByValueKey('login_button');
  }

  async getRegisterButton() {
    return await this.findByValueKey('register_link');
  }

  async login(email, password, role = 'student') {
    const emailEl = await this.getEmailField();
    const passEl = await this.getPasswordField();
    const loginBtn = await this.getLoginButton();

    if (email) await emailEl.setValue(email);
    if (password) await passEl.setValue(password);
    
    await loginBtn.click();
  }
}

module.exports = LoginPage;
