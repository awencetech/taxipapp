# Taxi Nanban - Enterprise Ride-Hailing Platform

## Overview

Taxi Nanban is an Uber/Ola-style ride-hailing platform built with enterprise-grade architecture.

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Node.js + Express
- **Database**: MongoDB
- **Cache**: Redis
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: GitHub Actions
- **Containerization**: Docker + Kubernetes

## Getting Started

### Backend

#### Using Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend
```

#### Local Development

```bash
cd backend

# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test
```

### Frontend (Vendor App)

```bash
cd vendorfrontend

# Install dependencies
flutter pub get

# Run development build
flutter run --dart-define=ENVIRONMENT=dev

# Run staging build
flutter run --dart-define=ENVIRONMENT=staging

# Run production build
flutter run --dart-define=ENVIRONMENT=prod
```

## Vendor Login Credentials

For testing purposes:
- **Email**: vendor@taxinanban.com
- **Password**: password123

## Project Structure

```
taxinanban/
├── backend/
│   ├── config/
│   ├── controllers/
│   ├── data/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── tests/
│   └── utils/
├── driverfrontend/
├── userfrontend/
├── vendorfrontend/
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── main.dart
│   └── test/
├── .github/
│   └── workflows/
├── monitoring/
├── docker-compose.yml
└── README.md
```

## Documentation

- [Architecture Overview](./ARCHITECTURE.md)
- [Migration Plan](./MIGRATION_PLAN.md)
