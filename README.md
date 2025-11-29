🍽️ Flutter Recipes App




A modern, intuitive recipe management application built with Flutter, Firebase, and Riverpod, designed to make it easy to browse, create, edit, and share cooking recipes.
The app includes features such as user accounts, favorites, search & filters, ratings, comments, PDF export, and more.

✨ Features
👤 User Accounts

Register & login using Firebase Authentication

Update display name and profile picture

View personal account information

Manage your own recipes

🍳 Recipes

Create, edit, and delete recipes

Upload recipe photos (Cloudinary)

View detailed recipe pages with ratings, ingredients, and instructions

Export any recipe to PDF format

Add recipes to favorites

See average rating and user reviews

🔍 Search & Filters

Search recipes by title

Filter recipes by:

difficulty

preparation time

categories

user favorites

Smart UI: carousel disappears when filtering or searching

💬 Comments & Ratings

Users can leave comments on recipes

Rate recipes (1–5 stars)

Real-time updates from Firestore

🎨 UI & Experience

Light / Dark theme support

Clean modern layout

Carousel of top-rated recipes

Profile header with customizable display name

Smooth navigation using GoRouter / Flutter Navigator

🗄️ Tech Stack
Technology	Usage
Flutter 3.x	Main UI framework
Riverpod	State management
Firebase Auth	User authentication
Cloud Firestore	Recipes, users, comments storage
Firebase Storage	(Optional) image storage
Cloudinary	Recipe image upload
HTTP package	API calls
PDF package	Export recipes to PDF


🖥️ Demo Screenshots

Home Page
![Uploading home.jpg…]()

Recipe Detail
![recipe detail](https://github.com/user-attachments/assets/869ebf3f-11b9-453b-89b5-c5b61c2a7a74)
![recipe detail 2](https://github.com/user-attachments/assets/9c264bcf-43ed-4e31-9d01-62bb4cd11893)

Add / Edit Recipe
![add recipe](https://github.com/user-attachments/assets/c6c739a5-ea99-45ca-a60f-24edaad4bd7f)

Favorites & Profile
![favorites](https://github.com/user-attachments/assets/177e0d9b-6407-4498-941c-2084f3903a16)
![profile](https://github.com/user-attachments/assets/58fda874-0cb6-4436-b1c0-bd9b0ebfdc27)

search 
![search](https://github.com/user-attachments/assets/45f3cb85-9478-4d5b-8602-95e14c0b8512)

splash 
![splash](https://github.com/user-attachments/assets/77f02aad-2874-44e3-a92a-c7ce7f83e29f)


🚀 Installation & Setup

Clone the repo

git clone https://github.com/heyitsmanal/flutter_recipes_app.git
cd flutter_recipes_app


Install dependencies

flutter pub get


Add Firebase config files

google-services.json → android/app/

GoogleService-Info.plist → ios/Runner/

Run the app

flutter run


📜 License

This project is licensed under the MIT License — feel free to use and adapt it.
