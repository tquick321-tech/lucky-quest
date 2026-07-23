# Deployment Guide

## Flutter App Deployment

### Android

1. **Build APK**:
```bash
flutter build apk --release
```

2. **Build App Bundle** (for Play Store):
```bash
flutter build appbundle --release
```

3. **Upload to Google Play Console**:
- Create app in Play Console
- Upload app bundle
- Complete store listing
- Submit for review

### iOS

1. **Build iOS App**:
```bash
flutter build ios --release
```

2. **Archive in Xcode**:
- Open `ios/Runner.xcworkspace`
- Product > Archive
- Distribute to App Store Connect

3. **Upload to App Store Connect**:
- Create app in App Store Connect
- Upload build from Xcode
- Complete app information
- Submit for review

## Backend Deployment

### Heroku

1. **Create Heroku App**:
```bash
heroku create lucky-quest-backend
```

2. **Set Environment Variables**:
```bash
heroku config:set FIREBASE_PROJECT_ID=your_project_id
heroku config:set JWT_SECRET=your_jwt_secret
```

3. **Deploy**:
```bash
git push heroku master
```

### AWS EC2

1. **Launch EC2 Instance** with Ubuntu

2. **SSH into Instance**:
```bash
ssh ubuntu@your-instance-ip
```

3. **Install Node.js and PM2**:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
```

4. **Clone and Run**:
```bash
git clone your-repo
cd lucky_quest/backend
npm install
pm2 start src/server.js
```

### Google Cloud Platform

1. **Deploy to App Engine**:
```bash
gcloud app deploy
```

## Firebase Deployment

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Storage Rules
```bash
firebase deploy --only storage:rules
```

### Cloud Functions
```bash
firebase deploy --only functions
```

## Environment Variables

Required environment variables for backend:

- `PORT` - Server port (default: 3000)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase client email
- `JWT_SECRET` - JWT secret key
- `NODE_ENV` - Environment (development/production)

## Monitoring

- **Firebase Crashlytics** - Crash reporting
- **Firebase Analytics** - User analytics
- **Winston Logs** - Server logs
- **PM2** - Process management

## Support

For deployment issues, contact dev@luckyquest.com
