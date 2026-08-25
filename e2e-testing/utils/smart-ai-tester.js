const fs = require('fs');
const path = require('path');
const logger = require('../core/logger.util');

class SmartAITester {
  constructor(driver = null) {
    this.driver = driver;
    this.discoveredWidgets = [];
    this.generatedScenarios = [];
  }

  /**
   * Analyzes screen hierarchy / widget tree and automatically detects components
   */
  async analyzeScreen(screenName = 'ActiveScreen') {
    logger.info(`[Smart AI Tester] Analyzing screen: ${screenName}...`);
    let pageSource = '';

    if (this.driver && !this.driver.isMock) {
      try {
        pageSource = await this.driver.getPageSource();
      } catch (err) {
        logger.error(`[Smart AI Tester] Error reading page source: ${err.message}`);
      }
    } else {
      pageSource = `
        <hierarchy>
          <android.widget.EditText resource-id="email_input" text="" content-desc="Email Address" />
          <android.widget.EditText resource-id="password_input" text="" content-desc="Password" />
          <android.widget.Button resource-id="login_btn" text="Login" content-desc="login_button" />
          <android.widget.Spinner resource-id="role_dropdown" content-desc="role_dropdown" />
          <android.widget.CheckBox resource-id="remember_me" content-desc="remember_checkbox" />
          <android.widget.TextView text="Forgot Password?" content-desc="forgot_pass_link" />
        </hierarchy>
      `;
    }

    const widgetMatches = [
      { type: 'TextField', regex: /EditText|TextField|input/gi },
      { type: 'Button', regex: /Button|ElevatedButton|TextButton|IconButton/gi },
      { type: 'Dropdown', regex: /Spinner|DropdownButton|Select/gi },
      { type: 'Checkbox', regex: /CheckBox|Checkbox/gi },
      { type: 'Radio', regex: /RadioButton|Radio/gi },
      { type: 'Link', regex: /TextView|ClickableText|link/gi }
    ];

    this.discoveredWidgets = [];
    widgetMatches.forEach(widgetType => {
      const matches = pageSource.match(widgetType.regex) || [];
      matches.forEach((m, idx) => {
        this.discoveredWidgets.push({
          id: `WIDGET_${widgetType.type.toUpperCase()}_${idx + 1}`,
          type: widgetType.type,
          screen: screenName,
          locator: `ValueKey(${widgetType.type.toLowerCase()}_${idx + 1})`
        });
      });
    });

    logger.info(`[Smart AI Tester] Discovered ${this.discoveredWidgets.length} widgets on ${screenName}.`);
    return this.discoveredWidgets;
  }

  /**
   * Generates test scenarios from discovered widgets dynamically
   */
  generateScenarios() {
    logger.info('[Smart AI Tester] Auto-generating test scenarios from discovered widgets...');
    this.generatedScenarios = [];

    this.discoveredWidgets.forEach(widget => {
      if (widget.type === 'TextField') {
        this.generatedScenarios.push({
          id: `AI_GEN_${this.generatedScenarios.length + 1}`,
          widgetId: widget.id,
          scenarioName: `Dynamic required field validation for ${widget.id}`,
          action: 'Leave field empty and submit',
          expectedResult: 'Display validation message "Field cannot be empty"'
        });
        this.generatedScenarios.push({
          id: `AI_GEN_${this.generatedScenarios.length + 1}`,
          widgetId: widget.id,
          scenarioName: `Boundary length test for ${widget.id}`,
          action: 'Input 256 characters payload',
          expectedResult: 'Truncate input or display max length error'
        });
      } else if (widget.type === 'Button') {
        this.generatedScenarios.push({
          id: `AI_GEN_${this.generatedScenarios.length + 1}`,
          widgetId: widget.id,
          scenarioName: `Click responsiveness test for ${widget.id}`,
          action: 'Tap button and capture navigation transition',
          expectedResult: 'Trigger screen navigation or state update'
        });
      } else if (widget.type === 'Dropdown') {
        this.generatedScenarios.push({
          id: `AI_GEN_${this.generatedScenarios.length + 1}`,
          widgetId: widget.id,
          scenarioName: `Option selection validation for ${widget.id}`,
          action: 'Select item from dropdown menu',
          expectedResult: 'Selected value reflected in form state'
        });
      }
    });

    logger.info(`[Smart AI Tester] Generated ${this.generatedScenarios.length} dynamic AI test scenarios.`);
    return this.generatedScenarios;
  }

  /**
   * Saves AI Test Report artifact
   */
  saveAIReport() {
    const reportPath = path.join(__dirname, '../reports/smart_ai_discovery_report.json');
    const reportData = {
      timestamp: new Date().toISOString(),
      discoveredWidgets: this.discoveredWidgets,
      generatedScenarios: this.generatedScenarios
    };

    fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2), 'utf8');
    logger.info(`[Smart AI Tester] Saved AI Discovery Report to: ${reportPath}`);
    return reportPath;
  }
}

module.exports = SmartAITester;

if (require.main === module) {
  const aiTester = new SmartAITester();
  aiTester.analyzeScreen('LoginScreen')
    .then(() => {
      aiTester.generateScenarios();
      aiTester.saveAIReport();
    });
}
