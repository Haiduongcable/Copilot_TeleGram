# Frontend-Backend Integration Guide

## ? Completed Steps

### 1. Code Generation
- ? Fixed dependency conflicts (disabled incompatible `custom_lint_core`)
- ? Successfully ran `flutter pub get`
- ?? Build runner partially configured (freezed/json_serializable ready, riverpod_generator disabled due to compatibility)

### 2. API Configuration
- ? Updated `main_development.dart` to point to `http://localhost:8000/api`
- ? Configured WebSocket endpoints to `ws://localhost:8000`
- ? Mapped API endpoints to match backend routes:
  - Auth: `/v1/auth`
  - Users: `/v1/users`
  - Posts/Feed: `/v1/posts`
  - Messaging: `/v1/chats`
  - Notifications: `/v1/notifications`
  - Admin: `/v1/admin`
  - Search: `/v1/search`
  - Files: `/v1/files`

### 3. Data Models
- ? Updated `User` model to handle backend schema:
  - Maps `_id` Å® `id`
  - Maps `full_name` Å® `name`
  - Maps `last_seen_at` Å® `lastSeen`
  - Handles both camelCase and snake_case fields

### 4. Authentication Repository
- ? Updated `RestAuthRepository` to match backend API:
  - **Login**: Sends `email` and `password`, receives `tokens` and `user`
  - **Register**: Sends `full_name`, `username`, `email`, `password`, `department`
  - **Refresh**: Sends `refresh_token`, receives new token pair
  - **Logout**: Sends `refresh_token` to invalidate session
  - **Current User**: Calls `/v1/users/me` to fetch user profile

### 5. Token Management
- ? JWT tokens stored securely via `flutter_secure_storage`
- ? Automatic token injection in HTTP headers via Dio interceptor
- ? Auto-logout on 401 responses

---

## ? Backend API Endpoints (localhost:8000)

### Authentication (`/api/v1/auth`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | Register new user |
| POST | `/login` | Login with email/password |
| POST | `/refresh` | Refresh access token |
| POST | `/logout` | Logout (invalidate refresh token) |
| POST | `/logout-all` | Logout all sessions |

### Users (`/api/v1/users`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/me` | Get current user profile |
| PATCH | `/me` | Update current user profile |
| POST | `/me/password` | Change password |
| GET | `/?q=<query>` | Search users |
| GET | `/{user_id}` | Get user by ID |

### Posts (`/api/v1/posts`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get feed (paginated) |
| POST | `/` | Create new post |
| GET | `/{post_id}` | Get post by ID |
| PATCH | `/{post_id}` | Update post |
| DELETE | `/{post_id}` | Delete post |
| POST | `/{post_id}/like` | Like/unlike post |
| POST | `/{post_id}/comment` | Add comment |

### Messaging (`/api/v1/chats`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/conversations` | Get all conversations |
| POST | `/conversations` | Create new conversation |
| GET | `/conversations/{id}/messages` | Get messages |
| POST | `/conversations/{id}/messages` | Send message |
| PATCH | `/messages/{id}` | Edit message |
| DELETE | `/messages/{id}` | Delete message |

### Notifications (`/api/v1/notifications`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all notifications |
| POST | `/mark-read` | Mark notifications as read |

### Files (`/api/v1/files`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/upload` | Upload file/image |
| GET | `/{file_id}` | Download file |

### WebSocket (`/ws/chat`)
- Real-time messaging
- Typing indicators
- Presence updates

---

## ? Running the Application

### 1. Start Backend
```bash
cd backend
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uvicorn app.main:app --reload
```
Backend will be available at `http://localhost:8000`

### 2. Start Frontend (Development)
```bash
cd frontend
flutter run -t lib/main_development.dart
```

Or simply:
```bash
cd frontend
flutter run
```

### 3. Test Authentication Flow
1. Open the app
2. Click "Register" or "Sign Up"
3. Fill in:
   - Name: `Test User`
   - Email: `test@example.com`
   - Password: `password123`
   - Department: `Engineering`
4. Click Register
5. After successful registration, you'll be logged in automatically

---

## ? Testing Backend API

You can test the API using the built-in docs:
- Swagger UI: `http://localhost:8000/api/docs`
- ReDoc: `http://localhost:8000/api/redoc`

### Example: Register User
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "full_name": "Test User",
    "password": "password123",
    "department": "Engineering"
  }'
```

### Example: Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Response:
```json
{
  "tokens": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_expires_in": 604800
  },
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "email": "test@example.com",
    "username": "testuser",
    "full_name": "Test User",
    "department": "Engineering",
    ...
  }
}
```

---

## ?? Known Issues & Pending Work

### Minor Issues
1. **Build Runner**: `riverpod_generator` disabled due to `custom_lint_core` compatibility issues
   - Impact: Riverpod code generation not available
   - Workaround: Manual provider definitions work fine
   
2. **Deprecation Warnings**: Some Material 3 properties deprecated
   - `surfaceVariant` Å® use `surfaceContainerHighest`
   - `background` Å® use `surface`
   - Impact: Visual only, no functional issues

3. **Unused Imports**: Several unused imports detected by analyzer
   - Impact: None, just code cleanup needed

### Pending Implementation
1. ? Auth flow - COMPLETED
2. ? Feed/Posts - Models ready, needs API integration
3. ? Messaging - Models ready, needs WebSocket integration
4. ? File Upload - Needs multipart implementation
5. ? Offline Caching - Isar setup pending
6. ? Push Notifications - Backend support needed first

---

## ? Next Steps

### Immediate (High Priority)
1. **Test Auth Flow End-to-End**
   - Register a user via mobile app
   - Login and verify token persistence
   - Test logout and re-login
   - Test auto-logout on 401

2. **Implement Feed Repository**
   - Update `RestFeedRepository` to call `/v1/posts`
   - Map `Post` model to match backend schema
   - Test creating and viewing posts

3. **Implement Messaging**
   - Set up WebSocket connection via `web_socket_channel`
   - Implement real-time message receiving
   - Test sending messages

### Short Term
4. **File Upload**
   - Implement multipart upload in `RestAuthRepository` for avatar
   - Add image picker integration
   - Test avatar upload

5. **Offline Support**
   - Configure Isar collections
   - Implement cache-first data strategy
   - Add sync indicators

6. **Error Handling**
   - Add user-friendly error messages
   - Implement retry logic for failed requests
   - Handle network disconnections gracefully

### Medium Term
7. **WebSocket Integration**
   - Real-time messaging
   - Typing indicators
   - Presence/online status
   - Notification push

8. **Complete Remaining Features**
   - Comments
   - Reactions
   - Search
   - Notifications
   - Admin panel

---

## ? Debugging Tips

### Frontend Debugging
```bash
# Run with verbose logging
flutter run -v

# Check logs
flutter logs

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal
```

### Backend Debugging
```bash
# Check logs
tail -f backend/logs/app.log

# Test MongoDB connection
mongo mongodb://localhost:27017/telegramapp

# Check running processes
ps aux | grep uvicorn
```

### Common Issues

**Issue**: `DioException: Connection refused`
- **Solution**: Ensure backend is running on `localhost:8000`

**Issue**: `401 Unauthorized` after login
- **Solution**: Check token storage and Dio interceptor configuration

**Issue**: `User model parsing error`
- **Solution**: Check field mappings in `User.fromJson()`

---

## ? Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Guide](https://riverpod.dev/)
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [MongoDB Manual](https://www.mongodb.com/docs/)

---

**Status**: ? Basic integration complete, ready for testing!
**Last Updated**: October 2, 2025
