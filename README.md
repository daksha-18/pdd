# HostelCare – Digital Hostel Complaint & Maintenance System

A production-ready mobile application for managing hostel complaints and maintenance with Flutter, Node.js, and MongoDB.

## Features
- 🔐 JWT Authentication with role-based access (Student, Admin, Staff)
- 📝 Submit & track complaints with image upload
- 📊 Admin analytics dashboard with charts
- 🤖 AI-powered chatbot for complaint assistance
- 📱 QR code scanning for auto-location fill
- 🔔 Real-time push notifications via Firebase
- 🌙 Dark/Light mode support
- 📶 Offline-first with auto-sync
- 🔄 Real-time updates via WebSockets

## Tech Stack
- **Frontend**: Flutter (Dart) with Material Design 3
- **Backend**: Node.js + Express.js
- **Database**: MongoDB with Mongoose
- **Cloud**: Firebase (Notifications), Cloudinary (Image CDN)

## Quick Start

### Backend
```bash
cd backend
npm install
cp .env.example .env   # Edit with your credentials
npm run seed            # Seed test data
npm run dev             # Start dev server
```

### Flutter App
```bash
cd hostelcare
flutter pub get
flutter run
```

## Test Credentials
| Role | Email | Password |
|------|-------|----------|
| Admin | admin@hostelcare.com | admin123 |
| Staff | rajesh@hostelcare.com | staff123 |
| Student | amit@student.com | student123 |

## Documentation
See `deployment_guide.md` for full setup, deployment, and Play Store instructions.

## License
MIT
