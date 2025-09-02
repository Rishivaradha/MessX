# Production Deployment for Play Store

## Current Issue
Your app only works with USB connection to your laptop. For Play Store deployment, you need:

1. **Cloud WebSocket Server** - Running 24/7, accessible worldwide
2. **Multi-user Support** - Unlimited users can connect simultaneously  
3. **Real User Discovery** - Show actual online users, not fake device scanning

## Deploy WebSocket Server (Choose One)

### Option 1: Render.com (Recommended)
1. Go to https://render.com/
2. Click "New" → "Web Service"
3. Connect GitHub repo with your `server/` folder
4. Settings:
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Environment: Node
5. Deploy → Get URL like `https://your-app.onrender.com`

### Option 2: Railway
```bash
cd server
npx @railway/cli login
npx @railway/cli new
npx @railway/cli up
npx @railway/cli domain
```

### Option 3: Glitch (Easiest)
1. Go to https://glitch.com/
2. New Project → Import from GitHub
3. Upload your server files
4. Auto-deploys to `https://your-project.glitch.me`

## Update Flutter App
Replace the WebSocket URL in `lib/services/websocket_service.dart`:
```dart
static const String _serverUrl = 'wss://your-deployed-server.com';
```

## Test Multi-User
1. Deploy server to cloud
2. Update Flutter app with cloud URL
3. Build APK and install on multiple devices
4. Test real-time chat between devices
5. Users appear/disappear in real-time

## For Play Store
- Server runs 24/7 in cloud
- Unlimited users can install and chat
- No dependency on your laptop
- Real user discovery from server
