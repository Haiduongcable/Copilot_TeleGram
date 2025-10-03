# ? Quick Start Guide

## Prerequisites
- ? Backend running on `http://localhost:8000`
- ? Flutter installed and configured
- ? Android/iOS device or emulator

## Start in 3 Steps

### Step 1: Verify Backend
```bash
./test_backend.sh
```
You should see:
```
? Backend is running!
? API docs available
? User registration successful
```

### Step 2: Start Flutter App
```bash
cd frontend
flutter run
```

### Step 3: Register & Login
1. Open app
2. Tap "Create Account"
3. Fill form:
   - Name: `Test User`
   - Email: `test@example.com` 
   - Password: `password123`
   - Department: `Engineering`
4. Tap "Register"
5. ? You're in!

## Common Commands

### Backend
```bash
# Start backend
cd backend && uvicorn app.main:app --reload

# View logs
tail -f backend/logs/app.log

# Access API docs
open http://localhost:8000/api/docs
```

### Frontend
```bash
# Run app (development mode)
cd frontend && flutter run

# Hot reload (while app is running)
Press 'r' in terminal

# Clean build
flutter clean && flutter pub get && flutter run

# Run tests
flutter test

# Check for issues
flutter analyze
```

## Troubleshooting

### "Backend not responding"
```bash
# Check if running
curl http://localhost:8000/api/health

# Restart backend
cd backend
uvicorn app.main:app --reload
```

### "Flutter build failed"
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### "Cannot register user"
Check backend logs for errors:
```bash
# View recent logs
tail -n 50 backend/logs/app.log
```

## What's Next?

After auth is working, you can start implementing:

1. **Feed** - View and create posts
2. **Messaging** - Real-time chat
3. **Profiles** - View team members
4. **Files** - Upload images/documents

See `COMPLETION_SUMMARY.md` for detailed next steps.

---

**Need Help?**
- Backend API Docs: http://localhost:8000/api/docs
- Integration Guide: See `INTEGRATION_GUIDE.md`
- Full Summary: See `COMPLETION_SUMMARY.md`
