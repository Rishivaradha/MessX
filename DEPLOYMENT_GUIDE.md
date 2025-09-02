# Deploy WebSocket Server to Cloud

## Quick Deploy to Railway (Free)

1. **Sign up at Railway**: https://railway.app/
2. **Connect GitHub**: Link your GitHub account
3. **Create new project**: Click "New Project" → "Deploy from GitHub repo"
4. **Upload server folder**: Create a new GitHub repo with the `server/` folder contents
5. **Auto-deploy**: Railway will detect Node.js and deploy automatically

## Quick Deploy to Render (Free)

1. **Sign up at Render**: https://render.com/
2. **New Web Service**: Click "New" → "Web Service"
3. **Connect repo**: Link GitHub repo containing server folder
4. **Settings**:
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Environment: Node
5. **Deploy**: Click "Create Web Service"

## Quick Deploy to Glitch (Easiest)

1. **Go to Glitch**: https://glitch.com/
2. **New Project**: Click "New Project" → "glitch-hello-node"
3. **Replace files**: Delete existing files and copy these files:
   - `package.json`
   - `websocket_server.js`
4. **Auto-deploy**: Glitch automatically runs your server

## Update Flutter App

After deployment, update the WebSocket URL in your Flutter app:

```dart
// In lib/services/websocket_service.dart
static const String _serverUrl = 'wss://your-app-name.onrender.com';
// or
static const String _serverUrl = 'wss://your-app-name.glitch.me';
```

## Test Remote Connection

1. Deploy server to cloud
2. Update Flutter app with new URL
3. Build and install app on phone
4. Test without USB connection
5. App will work even when laptop is off!

Your server will be online 24/7 for free on these platforms.
