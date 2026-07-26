# FoodDelivery-System 🍽️

A production-ready food delivery platform built for local restaurants.
The system includes a customer mobile application, restaurant admin dashboard, backend API, order management, delivery location tracking, and automated order lifecycle management.

---

## 🚀 Overview

FoodDelivery-System is a full-stack food ordering solution designed for small and medium-sized restaurants.

Customers can browse menus, place Cash on Delivery orders, share delivery location, and track their orders.

Restaurant admins can manage incoming orders, update order status, view revenue, and open customer delivery locations directly in Google Maps.

---

## ✨ Features

### Customer Application

* Browse restaurant menu
* View food images and details
* Add items to cart
* Place Cash on Delivery orders
* Automatic location permission request
* GPS-based delivery area validation
* 15 km delivery radius restriction
* Save customer delivery coordinates
* View previous orders using phone number
* Order status tracking

---

### Restaurant Admin Dashboard

* Secure admin login
* View all customer orders
* Real-time order management
* Update order status:

```
Pending
↓
Accepted
↓
Preparing
↓
Out For Delivery
↓
Delivered
```

* View order details
* View total revenue
* Open customer location in Google Maps
* Track customer using saved latitude and longitude
* Manage restaurant operations

---

## 🏗️ System Architecture

```
                Customer App
                    |
                    |
              REST API
                    |
                    |
              Node.js Backend
                    |
        -----------------------
        |                     |
    MongoDB Atlas        Supabase Storage
        |
        |
   Admin Dashboard
```

---

# 🛠️ Tech Stack

## Frontend (Customer App)

* Flutter
* Dart
* Riverpod State Management
* REST API Integration
* Google Maps Integration
* Location Services

---

## Backend

* Node.js
* Express.js
* TypeScript
* MongoDB
* Mongoose
* JWT Authentication
* REST API Architecture

---

## Database & Storage

### MongoDB Atlas

Used for:

* Users
* Orders
* Menu Items
* Order history

### Supabase Storage

Used for:

* Food images
* Restaurant assets

---

# 📂 Project Structure

```
FoodDelivery-System

│
├── backend
│
│   ├── src
│   │
│   ├── controllers
│   ├── services
│   ├── repositories
│   ├── models
│   ├── routes
│   ├── middleware
│   └── server.ts
│
│
├── mobile-app
│
│   ├── lib
│   │
│   ├── screens
│   ├── models
│   ├── providers
│   ├── repositories
│   └── services
│
│
└── README.md
```

---

# ⚙️ Backend Setup

## Requirements

Install:

* Node.js 20+
* MongoDB Atlas Account
* Git

Clone repository:

```bash
git clone https://github.com/yourusername/FoodDelivery-System.git
```

Navigate:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

---


# ▶️ Run Backend

Development:

```bash
npm run dev
```

Production build:

```bash
npm run build
```

Start:

```bash
npm start
```

Backend runs:

```
http://localhost:4000
```

---

# 📱 Flutter App Setup

Navigate:

```bash
cd mobile-app
```

Install packages:

```bash
flutter pub get
```

Run:

```bash
flutter run
```

---

# 🌍 Location System

The application uses GPS coordinates for delivery validation.

Flow:

```
Customer opens checkout
        |
        |
Request location permission
        |
        |
Get GPS coordinates
        |
        |
Calculate distance from restaurant
        |
        |
Allow order if within 15 km
```

Stored data:

```
latitude
longitude
address
```

Admin can open:

```
Google Maps
↓
Customer exact coordinates
```

---

# 🗺️ Google Maps Integration

Customer location opens using:

```
https://www.google.com/maps/search/?api=1&query=LATITUDE,LONGITUDE
```

Example:

```
https://www.google.com/maps/search/?api=1&query=26.2200986,84.3471717
```

---

# 🗄️ Database Models

## Order Model

Stores:

```
orderId
customerName
phone
address
items
subtotal
deliveryCharge
total
paymentMethod
paymentStatus
orderStatus
latitude
longitude
createdAt
updatedAt
```

---

# ⏳ Automatic Order Cleanup

Completed orders are automatically removed.

Implementation:

MongoDB TTL Index

Rules:

```
Delivered orders
Cancelled orders

↓
After 24 hours

↓
Automatically deleted
```

Pending and processing orders are never deleted.

---

# 🔌 API Endpoints

## Menu

GET

```
/api/v1/menu
```

---

## Create Order

POST

```
/api/v1/orders
```

---

## Get Order By ID

GET

```
/api/v1/orders/:id
```

---

## Get Orders By Phone

GET

```
/api/v1/orders/phone/:phone
```

---

## Admin Orders

GET

```
/api/v1/admin/orders
```

---

## Update Order Status

PATCH

```
/api/v1/orders/:id/status
```

---

# 🚀 Deployment

## Backend Hosting

Supported:

* Render
* Railway
* AWS
* DigitalOcean

Environment variables must be added in hosting dashboard.

---

# 🔒 Security

Implemented:

* Environment variables
* JWT authentication
* Protected admin routes
* Input validation
* MongoDB schema validation
* API error handling

---

# 📈 Future Improvements

* Push notifications
* Socket.IO real-time order updates
* Delivery partner application
* Online payments
* Restaurant analytics
* Customer authentication
* Order tracking map

---

# 👨‍💻 Developer

Built as a complete full-stack food delivery solution.

Technologies:

Flutter + Node.js + TypeScript + MongoDB + Supabase

---

## License

This project is for learning, portfolio, and business implementation purposes.
