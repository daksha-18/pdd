const BasePage = require('./base.page');

class StudentDashboardPage extends BasePage {
  async getNewComplaintButton() { return await this.findByValueKey('new_complaint_btn'); }
  async getMyComplaintsTab() { return await this.findByValueKey('my_complaints_tab'); }
  async getProfileButton() { return await this.findByValueKey('profile_btn'); }
  async getLogoutButton() { return await this.findByValueKey('logout_btn'); }
}

class ComplaintPage extends BasePage {
  async getTitleField() { return await this.findByValueKey('complaint_title_input'); }
  async getCategoryDropdown() { return await this.findByValueKey('category_dropdown'); }
  async getDescriptionField() { return await this.findByValueKey('description_input'); }
  async getRoomNumberField() { return await this.findByValueKey('room_number_input'); }
  async getUrgencyRadio() { return await this.findByValueKey('urgency_radio'); }
  async getSubmitButton() { return await this.findByValueKey('submit_complaint_btn'); }
}

class AdminPage extends BasePage {
  async getUsersTab() { return await this.findByValueKey('admin_users_tab'); }
  async getComplaintsTab() { return await this.findByValueKey('admin_complaints_tab'); }
  async getAnalyticsTab() { return await this.findByValueKey('admin_analytics_tab'); }
  async getQRGeneratorButton() { return await this.findByValueKey('qr_gen_btn'); }
  async getAssignStaffButton() { return await this.findByValueKey('assign_staff_btn'); }
}

class StaffPage extends BasePage {
  async getAssignedTasksTab() { return await this.findByValueKey('staff_tasks_tab'); }
  async getStatusUpdateDropdown() { return await this.findByValueKey('status_dropdown'); }
  async getUpdateTaskButton() { return await this.findByValueKey('update_task_btn'); }
  async getStatsTab() { return await this.findByValueKey('staff_stats_tab'); }
}

module.exports = {
  StudentDashboardPage,
  ComplaintPage,
  AdminPage,
  StaffPage
};
