<div align="center">
  <img src="assets/images/logo.png" alt="Queen App Logo" width="200"/>

  # Queen App 🛍️👑

  **A modern, gamified e-commerce and store management application built with Flutter & Supabase.**  
  *Una aplicación moderna de comercio electrónico y gestión de tienda con gamificación, construida en Flutter y Supabase.*

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.io/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
</div>

<br/>

## 🇬🇧 English

### Overview
Queen App is a comprehensive mobile application designed to bridge the gap between physical retail and online ordering. It offers a premium shopping experience featuring a gamified reward system, real-time inventory management, and a built-in admin dashboard.

### Key Features 🚀
- **User Authentication:** Secure email/password login and user profiles powered by Supabase Auth.
- **Dynamic Catalog:** Browse products with categories, gender filters, and stock status indicators (In-store vs. Pre-order).
- **Gamification System:** Users earn coins and level up (e.g., Novato, Bronce, Plata) by logging in consecutively (streaks) and completing purchases.
- **Admin Dashboard:** Integrated admin panel to manage products, categories, and orders seamlessly without needing a separate web app.
- **WhatsApp Checkout:** Orders are recorded in the database and then directly routed to WhatsApp for personalized customer service and payment confirmation.

### Screenshots 📸
<p align="center">
  <!-- 🖼️ PLACEHOLDER: Put your app screenshots inside the 'docs' or 'assets' folder and link them here -->
  <img src="https://via.placeholder.com/250x500.png?text=Login+Screen" width="200" alt="Login Screenshot"/> &nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Home+Catalog" width="200" alt="Catalog Screenshot"/> &nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Admin+Dashboard" width="200" alt="Admin Screenshot"/>
</p>

---

## 🇪🇸 Español

### Resumen
Queen App es una aplicación móvil integral diseñada para conectar las compras físicas con los pedidos en línea de tiendas modernas. Ofrece una experiencia de compra premium destacada por un sistema de recompensas gamificado, gestión de inventario en tiempo real y un panel de administración integrado directamente en la app.

### Características Principales 🚀
- **Autenticación:** Inicio de sesión seguro y gestión de perfiles utilizando Supabase Auth.
- **Catálogo Dinámico:** Navegación por categorías, género y estado de inventario (Entrega inmediata vs. Bajo pedido de 15-20 días).
- **Sistema de Gamificación:** Los clientes ganan monedas y suben de rango (Novato, Bronce, Plata, etc.) al mantener sus rachas de inicio de sesión y realizar compras.
- **Panel de Administrador:** Gestión nativa de productos, categorías y pedidos de ventas sin necesidad de acceder a otra plataforma.
- **Checkout por WhatsApp:** Los pedidos se guardan en la base de datos y dirigen al cliente a confirmar su pago y detalles de envío a través de WhatsApp.

### Capturas de Pantalla 📸
<p align="center">
  <!-- 🖼️ REEMPLAZA ESTAS IMÁGENES: Sube tus capturas a una carpeta 'docs' o 'assets' y enlaza la ruta aquí -->
  <img src="https://via.placeholder.com/250x500.png?text=Login+Screen" width="200" alt="Pantalla de Login"/> &nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Home+Catalog" width="200" alt="Catálogo"/> &nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Admin+Dashboard" width="200" alt="Dashboard de Admin"/>
</p>

---

## 🛠️ Architecture & Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage)
- **State Management:** BLoC (Business Logic Component) Pattern
- **Routing:** GoRouter
- **Design System:** Custom UI with tailored micro-animations and a cohesive color palette.

## ⚙️ Setup & Installation

To run this project locally, you will need to set up your own Supabase instance and add your keys.

1. Clone the repository:
   ```bash
   git clone https://github.com/YourUsername/Queen-App.git
   ```
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Create a `.env` file in the root directory (already ignored in `.gitignore`) and add your Supabase credentials:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   ADMIN_EMAILS=admin@store.com
   WHATSAPP_NUMBER=584141234567
   ```
4. Run the app:
   ```bash
   flutter run
   ```
