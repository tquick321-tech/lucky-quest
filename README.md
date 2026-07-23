# Lucky Quest

A mobile gaming rewards platform where users play games to earn coins and redeem rewards.

## Features

- **Multiple Games**: Play various casual games to earn coins
- **Reward System**: Redeem coins for gift cards, PayPal, and crypto
- **VIP Tiers**: Progress through VIP levels for multipliers and perks
- **Daily Challenges**: Complete daily tasks for bonus rewards
- **Referral System**: Invite friends and earn bonuses
- **Leaderboards**: Compete with players globally
- **Achievements**: Unlock badges and rewards

## Tech Stack

### Frontend (Flutter)
- Flutter 3.0+
- Firebase (Auth, Firestore, Storage, Messaging)
- Provider for state management
- Lottie for animations

### Backend (Node.js)
- Express.js
- Firebase Admin SDK
- JWT authentication
- WebSocket (Socket.io)
- Winston logging

## Project Structure

```
lucky_quest/
├── lib/                          # Flutter app
│   ├── constants/               # App constants
│   ├── core/                    # Theme and utilities
│   ├── models/                  # Data models
│   ├── screens/                 # UI screens
│   ├── services/                # Firebase services
│   └── main.dart               # App entry point
├── backend/                     # Node.js API
│   ├── src/
│   │   ├── routes/             # API routes
│   │   ├── middleware/         # Auth, validation
│   │   ├── services/           # Firebase integration
│   │   ├── utils/              # Helpers
│   │   └── server.js           # Server entry
│   └── package.json
├── android/                     # Android native code
├── ios/                         # iOS native code
└── pubspec.yaml                # Flutter dependencies
```

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- Firebase project

### Flutter Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Configure Firebase:
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`

3. Run the app:
```bash
flutter run
```

### Backend Setup

1. Install dependencies:
```bash
cd backend
npm install
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your Firebase credentials
```

3. Start the server:
```bash
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Wallet
- `GET /api/wallet` - Get wallet balance
- `GET /api/wallet/transactions` - Get transaction history
- `POST /api/wallet/add` - Add coins
- `POST /api/wallet/deduct` - Deduct coins

### Games
- `GET /api/games` - Get available games
- `POST /api/games/start` - Start game session
- `POST /api/games/end` - End game session

### Rewards
- `GET /api/rewards` - Get available rewards
- `POST /api/rewards/request` - Request withdrawal

## VIP Tiers

- **Bronze**: 1.0x multiplier (0 coins)
- **Silver**: 1.2x multiplier (10,000 coins)
- **Gold**: 1.5x multiplier (50,000 coins)
- **Platinum**: 2.0x multiplier (100,000 coins)
- **Diamond**: 2.5x multiplier (250,000 coins)

## License

MIT License
