# Internal Team Social Network - Project Brief

## Vision
Build a simple, self-hosted social network + messaging app (Facebook + messenger + telegram) for internal team communication and collaboration. Easy to deploy locally or on a single cloud VM, with no expensive third-party services required.

---

## Core Features (Simplified)

### 1. Authentication & User Management

#### User Registration & Login
- **Registration**: Email + password (no SMS verification needed)
- **Login**: Email + password with JWT tokens
- **Session Management**: JWT access tokens (1 hour) + refresh tokens (7 days)
- **Password Reset**: Via email (optional - can be manual admin reset)
- **Logout**: Invalidate tokens

#### User Profile
- **Basic Info**: Name, username, email, bio, department/role
- **Profile Picture**: Upload and display avatar
- **Status**: Online/offline, custom status message
- **Privacy**: Simple visibility (all team members can see profiles)

---

### 2. Social Features

#### Team Directory
- **User List**: Browse all team members
- **Search**: Find users by name, username, email, department
- **User Profile View**: See basic info and recent posts

#### Posts & Feed
- **Create Posts**:
  - Text posts (with basic formatting)
  - Attach images (single or multiple)
  - Attach files (PDFs, docs - with size limit)
  - Tag team members (@mention)
- **News Feed**: 
  - Chronological feed of all team posts
  - Filter by user or department
  - Simple pagination (load more)
- **Post Actions**:
  - Edit/delete your own posts
  - Pin important announcements

#### Reactions & Comments
- **Reactions**: Simple like button (can expand to ???? later)
- **Comments**:
  - Add comments to posts
  - Edit/delete your own comments
  - Simple nested replies (1 level deep)
  - @mention in comments
- **Shares**: Share post to your timeline with optional comment

---

### 3. Messaging System

#### Chat Types
- **1:1 Direct Messages**: Private conversations between two users
- **Group Chats**: 
  - Create group with multiple members
  - Group name and optional group photo
  - Add/remove members (creator = admin)
  - Leave group

#### Messaging Features
- **Message Types**:
  - Text messages
  - Emoji support (native emoji picker)
  - Images and files
  - Reply to specific message
- **Message Actions**:
  - Edit message (within 5 minutes)
  - Delete message (for yourself or everyone)
  - Copy message text
- **Real-time Features**:
  - Typing indicators
  - Read receipts (seen by)
  - Online/offline status
  - Last seen timestamp
- **Chat Management**:
  - Unread message count
  - Mark conversation as read
  - Archive conversations
  - Delete conversation history
  - Search messages within conversation

---

### 4. Notifications

#### Notification Types
- **In-App Only** (no SMS, no email):
  - New messages
  - Post reactions
  - Comments on your posts
  - @mentions in posts/comments
  - Added to group chat

#### Notification Center
- **Notification List**: All notifications with read/unread status
- **Mark as Read**: Clear individual or all notifications
- **Real-time**: WebSocket push for instant updates

---

### 5. File & Media Management

#### Upload & Storage
- **Local Storage**: Store files on server filesystem or MinIO (S3-compatible)
- **Image Uploads**: Auto-resize and create thumbnails
- **File Limits**: 
  - Images: max 10MB each
  - Files: max 50MB each
  - Storage per user: 1GB (configurable)
- **Supported Formats**:
  - Images: JPG, PNG, GIF
  - Documents: PDF, DOC, DOCX, XLS, XLSX, TXT

---

### 6. Admin Panel (Simple)

#### Admin Features
- **User Management**:
  - View all users
  - Activate/deactivate accounts
  - Reset user passwords manually
  - Delete users
- **Content Moderation**:
  - View all posts
  - Delete inappropriate posts/comments
- **Basic Stats**:
  - Total users, posts, messages
  - Storage usage
  - Active users today

---

## Technical Stack (Simplified)

### Backend
- **Framework**: FastAPI (Python 3.11+)
- **Database**: MongoDB (single instance, easy setup)
- **Cache/Queue**: Redis (sessions, real-time data, task queue)
- **Real-Time**: FastAPI WebSocket
- **Task Queue**: Simple background tasks with FastAPI BackgroundTasks or lightweight Celery

### Storage
- **File Storage**: 
  - Option 1: Local filesystem (simple, for single server)
  - Option 2: MinIO (S3-compatible, self-hosted, for scalability)
- **Static Files**: Served directly by FastAPI or Nginx

### No External Services Needed ?
- ? No SMS providers (Twilio, etc.)
- ? No email services (SendGrid) - use simple SMTP if needed
- ? No push notifications (APNs/FCM) - WebSocket only
- ? No payment gateways
- ? No CDN required
- ? No video processing
- ? No AI/ML services

---

## Architecture (Simple Deployment)

### Single Server Setup (Recommended for Start)
```
„¡„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„¢
„          AWS/GCP VM Instance         „ 
„         (4 CPU, 8GB RAM, 100GB)      „ 
„¥„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„§
„  Docker Compose:                     „ 
„   - FastAPI (app container)          „ 
„   - MongoDB (database)               „ 
„   - Redis (cache/websocket)          „ 
„   - MinIO (optional storage)         „ 
„   - Nginx (reverse proxy)            „ 
„¤„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„Ÿ„£
```

### Components
1. **FastAPI Backend**: All REST APIs + WebSocket server
2. **MongoDB**: Single database for all data
3. **Redis**: Session storage, WebSocket pub/sub, caching
4. **MinIO**: (Optional) S3-compatible file storage
5. **Nginx**: Reverse proxy, SSL termination, static file serving

---

## API Structure (Simplified)

### REST API Endpoints
```
/api/v1/
  /auth/
    - POST /register
    - POST /login  
    - POST /logout
    - POST /refresh
    
  /users/
    - GET /me
    - PATCH /me
    - GET / (list all users)
    - GET /{user_id}
    - PATCH /me/avatar
    
  /posts/
    - GET / (feed)
    - POST /
    - GET /{post_id}
    - PATCH /{post_id}
    - DELETE /{post_id}
    - POST /{post_id}/like
    - POST /{post_id}/comment
    
  /comments/
    - PATCH /{comment_id}
    - DELETE /{comment_id}
    - POST /{comment_id}/reply
    
  /chats/
    - GET /conversations
    - POST /conversations
    - GET /conversations/{conv_id}/messages
    - POST /conversations/{conv_id}/messages
    - PATCH /messages/{message_id}
    - DELETE /messages/{message_id}
    
  /notifications/
    - GET /
    - POST /mark-read
    
  /files/
    - POST /upload
    - GET /{file_id}
```

### WebSocket
```
/ws/chat - Real-time messaging and presence
```

---

## MongoDB Collections

### Core Collections (7 total)
1. **users**: User accounts and profiles
2. **posts**: User posts with text and media
3. **comments**: Comments on posts
4. **conversations**: Chat metadata (participants, type)
5. **messages**: All chat messages
6. **notifications**: User notifications
7. **files**: Uploaded file metadata
---

## Development Phases

### Phase 1: Core Backend (2-3 weeks)
- ? User authentication (register, login, JWT)
- ? User profiles (CRUD, avatar upload)
- ? Basic posts (create, read, list feed)
- ? File upload system
- ? MongoDB setup with indexes

### Phase 2: Social Features (2-3 weeks)
- ? Likes and comments
- ? User mentions (@username)
- ? Search users and posts
- ? Edit/delete posts and comments

### Phase 3: Messaging (2-3 weeks)
- ? 1:1 direct messages
- ? Group chats
- ? WebSocket real-time delivery
- ? Read receipts and typing indicators
- ? Message edit/delete

### Phase 4: Polish & Deploy (1-2 weeks)
- ? Notifications system
- ? Admin panel basics
- ? Docker Compose setup
- ? Deploy to VM
- ? Basic monitoring


---

## Security (Simplified)

### Basic Security Measures
- ? Password hashing with bcrypt
- ? JWT token authentication
- ? HTTPS in production (Nginx + Let's Encrypt)
- ? CORS configuration for mobile app
- ? File type validation on uploads
- ? Rate limiting on auth endpoints (100 req/min)
- ? Input validation with Pydantic
- ? SQL injection safe (MongoDB with proper queries)


## Monitoring (Simple)

### Basic Monitoring
- **Logs**: Python logging to files + console
- **Health Check**: `/health` endpoint
- **Metrics**: Simple endpoint `/metrics` with:
  - Total users
  - Posts today
  - Messages today
  - Storage used
  - Uptime

### Tools (Optional)
- **Portainer**: Docker container management UI
- **Mongo Express**: MongoDB web admin
- **Redis Commander**: Redis web UI

---

## Mobile App Considerations

### API Design for Mobile
- **Pagination**: Cursor-based for infinite scroll
- **Optimized Payloads**: Only return needed fields
- **Image Sizes**: Serve thumbnails (256px) for lists, full size on demand
- **Offline Support**: Mobile app caches data locally
- **WebSocket Reconnection**: Handle connection drops gracefully

### Mobile Tech Stack Options
- **React Native**: Cross-platform (iOS + Android)
- **Flutter**: Modern UI, great performance
- **Native**: Separate iOS (Swift) + Android (Kotlin) if needed

---

## Cost Estimate (Monthly)

### Self-Hosted on Cloud VM
- **AWS EC2 t3.medium**: ~$35/month
- **GCP e2-medium**: ~$25/month  
- **Storage (100GB)**: ~$10/month
- **Total**: ~$35-45/month

### Local Hosting (Free)
- Use office server or spare machine
- **Cost**: $0 (just electricity)


## Success Criteria

### Must-Have for Launch
- ? Users can register and login
- ? Users can create posts with text and images
- ? Users can like and comment on posts
- ? Users can send 1:1 messages in real-time
- ? Users can create group chats
- ? Mobile app works offline (with cached data)
- ? System is stable for 50+ concurrent users

### Nice-to-Have (Post-Launch)
- Enhanced search functionality
- Better admin dashboard
- Export data features
- Automated backups
- Better image gallery view

---

## Next Steps

1. **Setup Development Environment**
   - Install Python 3.11+, Docker, Docker Compose
   - Setup MongoDB and Redis locally
   - Create project structure

2. **Build MVP Backend**
   - Start with auth system
   - Add user profiles
   - Implement basic posts
   - Add messaging

3. **Mobile App Development**
   - Choose tech stack (React Native recommended)
   - Design UI/UX mockups
   - Integrate with backend APIs
   - Test on real devices

4. **Deploy & Test**
   - Deploy to test VM
   - Invite team for beta testing
   - Gather feedback
   - Fix bugs and improve

5. **Launch**
   - Deploy to production
   - Train team on features
   - Monitor usage and performance