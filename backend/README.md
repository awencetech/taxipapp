# Taxi Nanban Backend

A production-ready backend for a taxi booking mobile application built with Node.js, Express.js, MongoDB, and Socket.IO.

## Tech Stack

- **Node.js**: Runtime environment
- **Express.js**: Web framework
- **MongoDB & Mongoose**: Database and ODM
- **Socket.IO**: Real-time communication (tracking, notifications)
- **JWT**: Authentication and Authorization
- **Google Maps API**: Distance, duration, and geolocation
- **Multer**: File uploads
- **Swagger**: API Documentation

## Project Structure

```text
controllers/    # Route controllers
models/         # Mongoose schemas
routes/         # API route definitions
middleware/     # Custom middleware (auth, error, etc.)
config/         # Configuration files (DB, etc.)
services/       # External services (Maps logic)
sockets/        # Socket.IO event handlers
utils/          # Utility functions
uploads/        # Static file storage
server.js       # Entry point
```

## Features

- **Authentication**: Email/Password
- **Real-time**: Live driver tracking, ride request broadcasting
- **Roles**: User, Driver, Admin
- **Ride Management**: Fare estimation, matching, status updates
- **Admin**: User/Driver management, revenue statistics

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   cd server
   npm install
   ```
3. Configure environment variables in `.env` (refer to `.env.example`)
4. Start the server:
   ```bash
   npm run dev
   ```

## API Documentation

Once the server is running, visit:
`http://localhost:5000/api-docs`

## Socket Events

- `join`: Join a user-specific room
- `updateLocation`: Driver sends real-time coordinates
- `requestRide`: User requests a ride (broadcasts to drivers)
- `acceptRide`: Driver accepts a ride request
- `rideStatusUpdate`: Updates on ride progress
