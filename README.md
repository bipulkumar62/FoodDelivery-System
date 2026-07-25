# 🍽️ Pawan Biryani Ordering System

A full-stack restaurant ordering system built for **Pawan Biryani**. The project allows customers to place orders from a mobile app while the restaurant owner manages incoming orders through an admin panel in real time.

---

## ✨ Features

### 👤 Customer App
- Browse menu
- Add items to cart
- Place orders
- Order confirmation
- View order status
- Responsive and modern UI

### 👨‍💼 Admin Panel
- Secure admin login
- View all incoming orders
- Update order status
- Manage completed and cancelled orders
- Revenue dashboard
- Automatic order management
- Real-time order updates (planned)

---

## 🛠 Tech Stack

### Frontend
- Flutter
- Dart
- Material Design

### Backend
- Node.js
- Express.js
- TypeScript
- REST API

### Database
- MongoDB Atlas
- Mongoose

### Deployment
- Render
- GitHub

---

## 📁 Project Structure

```
Pawan-Biryani/
│
├── frontend/
│   ├── customer_app/
│   └── admin_app/
│
├── backend/
│   ├── controllers/
│   ├── routes/
│   ├── models/
│   ├── middleware/
│   ├── services/
│   └── server.ts
│
└── README.md
```

---

## 🚀 Features Implemented

- Customer order placement
- Backend REST APIs
- MongoDB integration
- Admin authentication
- Order management
- Revenue calculation
- Status updates
- Render deployment
- Production-ready API structure
- Error handling
- Environment variable configuration

---

## 📡 API Overview

| Method | Endpoint | Description |
|---------|----------|-------------|
| GET | /api/v1/menu | Get menu |
| POST | /api/v1/orders | Create order |
| GET | /api/v1/orders | Get all orders |
| PUT | /api/v1/orders/:id | Update order |
| DELETE | /api/v1/orders/:id | Delete order |

---

## ⚙️ Installation

### Clone Repository

```bash
git clone https://github.com/yourusername/pawan-biryani.git
```

### Backend

```bash
cd backend
npm install
npm run dev
```

### Frontend

```bash
flutter pub get
flutter run
```

---

## 🔐 Environment Variables

Create a `.env` file inside the backend.

```env
PORT=5000

MONGODB_URI=your_mongodb_connection_string

JWT_SECRET=your_secret_key

NODE_ENV=production
```

---

## 📱 Screens

- Splash Screen
- Home
- Menu
- Cart
- Checkout
- Order Success
- Admin Login
- Admin Dashboard
- Orders
- Revenue Dashboard

---

## 📌 Roadmap

- [ ] Socket.IO real-time updates
- [ ] Push notifications
- [ ] Payment gateway
- [ ] Delivery partner app
- [ ] Analytics dashboard
- [ ] Banner management
- [ ] Customer authentication
- [ ] Search & filters
- [ ] Coupons & offers
- [ ] Multi-restaurant support

---

## 📈 Architecture

```
Flutter App
      │
      ▼
 REST API
      │
      ▼
Express + Node.js
      │
      ▼
 MongoDB Atlas
      │
      ▼
 Admin Dashboard
```

---

## 💻 Development

```bash
npm install
npm run dev
```

Build Flutter

```bash
flutter build apk
```

---

## 🤝 Contributing

Contributions, feature requests, and suggestions are welcome.

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Push the branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Yash**

Computer Science Student • Flutter Developer • Backend Developer • AI Enthusiast

---

⭐ If you found this project useful, consider giving it a star!
