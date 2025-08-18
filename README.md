# Wishlist App

A mobile application built with Flutter for managing wishlists and wish items. Users can create private or public wishlists, add items with details like name, description, price, and image, and share them. The app integrates with Supabase for backend services, including authentication, database, and storage.

## Features

*   User authentication (email/password, phone, Google Sign-In).
*   Create and manage multiple wishlists.
*   Add, edit, and delete wish items within a wishlist.
*   Set wishlists as private or public.
*   Image handling for wish items (upload to Supabase Storage).
*   Web scraping for item details (e.g., title, price, image from a URL).
*   Caching for faster image loading.
*   Filtering and sorting of wish items.

## Technologies Used

*   **Flutter:** UI Toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Dart:** Programming language used by Flutter.
*   **Supabase:** Open-source Firebase alternative providing:
    *   PostgreSQL Database
    *   Authentication
    *   Storage
*   **`cached_network_image`:** For efficient image caching.
*   **`url_launcher`:** For opening external URLs.
*   **`image_picker`:** For picking images from the gallery or camera.
*   **`google_sign_in`:** For Google authentication.
*   **`sms_autofill`:** For SMS OTP autofill.
*   **`http`:** For making HTTP requests (used in web scraping).

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel recommended)
*   [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/wishlist_app.git
    cd wishlist_app
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

### Supabase Setup

This project uses Supabase for its backend. You'll need to set up your own Supabase project.

1.  **Create a Supabase Project:**
    *   Go to [Supabase](https://supabase.com/) and create a new project.
    *   Note down your **Project URL** and **Anon Key** from Project Settings -> API.

2.  **Configure Environment Variables:**
    *   Rename `.env.example` to `.env`.
    *   Update the `.env` file with your Supabase project details:
        ```
        SUPABASE_URL=YOUR_SUPABASE_URL
        SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
        ```

3.  **Database Schema:**
    *   You'll need to set up the necessary tables and RLS policies in your Supabase project. Refer to the `lib/services/supabase_database_service.dart` for the expected table names and columns (e.g., `users`, `wishlists`, `wish_items`).
    *   For authentication, ensure you have enabled the desired providers (Email, Phone, Google) in your Supabase project's Authentication settings.

4.  **Google Sign-In (Android/iOS):**
    *   Follow the official `google_sign_in` plugin setup guide for [Android](https://pub.dev/packages/google_sign_in#android) and [iOS](https://pub.dev/packages/google_sign_in#ios).
    *   For Android, download your `google-services.json` file from Firebase and place it in `android/app/`.

### Running the App

To run the app on a connected device or emulator:

```bash
flutter run
```

## Project Structure

*   `lib/`: Main application source code.
    *   `config.dart`: Application-wide configurations.
    *   `main.dart`: Entry point of the application.
    *   `theme.dart`: Defines the application's visual theme.
    *   `models/`: Data models (e.g., `wishlist.dart`, `wish_item.dart`).
    *   `screens/`: UI for different screens/pages of the app.
    *   `services/`: Backend integration and utility services (e.g., `auth_service.dart`, `supabase_database_service.dart`, `image_cache_service.dart`, `web_scraper_service.dart`).
    *   `widgets/`: Reusable UI components.

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
