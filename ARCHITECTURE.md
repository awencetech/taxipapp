# Taxi Nanban Enterprise Architecture

## Overview

This document describes the enterprise-grade architecture for the Taxi Nanban ride-hailing platform, designed to scale to Uber/Ola levels of traffic.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                           │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ User App   │  │ Driver App   │  │ Vendor/Admin App│  │
│  │ (Flutter)   │  │ (Flutter)    │  │ (Flutter)       │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                      API Gateway                              │
│               (Load Balancing, SSL, Rate Limiting)                │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
┌────────▼──────┐ ┌───▼───────────┐ ┌──▼──────────────┐
│  Auth Service  │ │ Booking Service│ │ Payment Service │
└────────┬───────┘ └───┬───────────┘ └──┬───────────────┘
         │                │                │
┌────────▼──────┐  ┌──────▼───────┐  ┌──▼──────────┐
│Notification│  │ Location Service│  │Vehicle Service│
│  Service   │  └──────────────┘  └───────────────┘
└───────────────┘
         │
┌────────▼──────────────────┐
│     Redis Cache          │
│  (Nearby Drivers, OTPS,  │
│  Session Data, Fare Estimates│
└────────┬───────────────────┘
         │
┌────────▼──────────────────┐
│      MongoDB Cluster       │
└───────────────────────────┘
         │
┌────────▼──────────────────┐
│  Monitoring & Logging   │
│  Prometheus + Grafana  │
│        + Sentry         │
└───────────────────────────┘
         │
┌────────▼──────────────────┐
│  Docker + Kubernetes     │
└───────────────────────────┘
```

## Clean Architecture (Flutter)

### Layers:

1. **Presentation Layer** (UI + ViewModels/Providers)
2. **Domain Layer** (Use Cases + Repositories + Entities)
3. **Data Layer** (Data Sources + Repositories Implementation)

### Data Flow:
```
UI → ViewModel → UseCase → Repository → Data Source → API
```

## Backend Architecture (Node.js + Express)

### Services:

1. **Auth Service** - JWT-based authentication
2. **Booking Service** - Ride creation and management
3. **Payment Service** - Payment gateway integration
4. **Location Service** - Real-time driver tracking
5. **Notification Service** - Push notifications (Firebase)

## Environment Management

### Backend:
- `.env.development` - Local development
- `.env.production` - Production environment
- `.env.test` - Testing environment

### Flutter:
- `.env.dev` - Local development
- `.env.staging` - Staging environment
- `.env.prod` - Production environment

## CI/CD Pipeline

1. **Lint → Test → Build → Deploy

## Monitoring Stack:

- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **Sentry** - Error tracking
