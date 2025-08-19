# Wishlist App

![App Screenshot](https://example.com/screenshot.png) <!-- Replace with a real screenshot or GIF -->

A mobile application built with Flutter for managing wishlists and wish items. Users can create private or public wishlists, add items with details like name, description, price, and image, and share them. The app integrates with Supabase for backend services, including authentication, database, and storage.

## Table of Contents

- [Features](#features)
- [Technologies Used](#technologies-used)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Supabase Setup](#supabase-setup)
  - [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Contributing](#contributing)
- [License](#license)

## Features

*   **User Authentication:** Secure sign-up and sign-in with email/password, phone number (OTP), and Google Sign-In.
*   **Wishlist Management:** Create, edit, and delete multiple wishlists. Set wishlists as public or private.
*   **Wish Item Management:** Add, edit, and delete items within a wishlist. Include details like name, description, price, image, and a link to the product page.
*   **Image Handling:** Upload images for wish items from the gallery or camera. Images are stored in Supabase Storage.
*   **Web Scraping:** Automatically fetch item details (title, price, image) from a URL.
*   **Image Caching:** Efficiently cache images for faster loading and offline access.
*   **Filtering and Sorting:** Filter wish items by category and sort them by price or name.
*   **Social Features:** Share wishlists with friends and discover public wishlists from other users.

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
    *   You'll need to set up the necessary tables and RLS policies in your Supabase project. See the [Database Schema](#database-schema) section for more details.
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

## Database Schema

### `users`

| Column         | Type      | Description                                      |
|----------------|-----------|--------------------------------------------------|
| `id`           | `uuid`    | User ID (references `auth.users.id`)             |
| `display_name` | `text`    | User's display name                              |
| `email`        | `text`    | User's email address                             |
| `phone_number` | `text`    | User's phone number                              |
| `photo_url`    | `text`    | URL of the user's profile picture                |
| `is_private`   | `boolean` | Whether the user's profile is private or public  |

### `wishlists`

| Column       | Type      | Description                                      |
|--------------|-----------|--------------------------------------------------|
| `id`         | `uuid`    | Wishlist ID                                      |
| `owner_id`   | `uuid`    | ID of the user who owns the wishlist             |
| `name`       | `text`    | Name of the wishlist                             |
| `is_private` | `boolean` | Whether the wishlist is private or public        |
| `image_url`  | `text`    | URL of the wishlist's cover image                |
| `created_at` | `timestamp`| Timestamp of when the wishlist was created       |

### `wish_items`

| Column        | Type      | Description                                      |
|---------------|-----------|--------------------------------------------------|
| `id`          | `uuid`    | Wish item ID                                     |
| `wishlist_id` | `uuid`    | ID of the wishlist this item belongs to          |
| `name`        | `text`    | Name of the wish item                            |
| `description` | `text`    | Description of the wish item                     |
| `price`       | `float8`  | Price of the wish item                           |
| `link`        | `text`    | URL to the product page                          |
| `image_url`   | `text`    | URL of the wish item's image                     |
| `category`    | `text`    | Category of the wish item                        |
| `created_at`  | `timestamp`| Timestamp of when the wish item was created      |

## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.