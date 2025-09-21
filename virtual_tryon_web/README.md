# Virtual Fashion Hub 🛍️✨

A cutting-edge virtual try-on web application that leverages AI-powered technology to revolutionize the online fashion experience. Built with Flutter for the frontend and FastAPI for the backend, integrated with multiple ComfyUI models for realistic clothing visualization.

## 📋 Table of Contents
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [AI Models](#ai-models)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **AI-Powered Virtual Try-On**: Realistic clothing fitting using advanced computer vision
- **Multi-Model Support**: Integration with CatVTON, IDM-VTON, KolorVTON, and Florence models
- **Cross-Platform**: Web, Windows, and mobile support via Flutter
- **Firebase Authentication**: Secure user registration and login
- **MySQL Database**: Robust data storage and user management
- **Real-time Processing**: Fast image processing and virtual fitting
- **Responsive Design**: Modern, mobile-friendly interface
- **Image Upload**: Support for various image formats
- **Model Selection**: Choose between different AI models for different results

## 🚀 Technology Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language for Flutter
- **Firebase** - Authentication and hosting

### Backend
- **FastAPI** - Modern Python web framework
- **ComfyUI** - AI model workflow management
- **MySQL** - Database for user data and preferences
- **Python 3.10+** - Backend programming language

### AI Models
- **CatVTON** - High-quality virtual try-on
- **IDM-VTON** - Identity-preserving virtual try-on
- **KolorVTON** - Color-aware virtual fitting
- **Florence** - Image segmentation and analysis

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0+)
- **Python** (3.10+)
- **Node.js** (for Firebase CLI)
- **MySQL** (8.0+)
- **Git**

## 🛠️ Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/virtual-fashion-hub.git
cd virtual-fashion-hub
```

### 2. Frontend Setup (Flutter)
```bash
cd virtual_tryon_web
flutter pub get
flutter run -d web
```

### 3. Backend Setup (FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### 4. Database Setup
```sql
CREATE DATABASE virtual_tryon;
-- Import your database schema here
```

## ⚙️ Configuration

### 1. Environment Variables
Create a `.env` file in the backend directory:
```env
# Database
MYSQL_HOST=localhost
MYSQL_USER=your_username
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=virtual_tryon

# ComfyUI
COMFYUI_ENDPOINT=http://localhost:8188
MODEL_PATH=/path/to/your/models

# API Keys
FIREBASE_API_KEY=your_firebase_api_key
```

### 2. Firebase Configuration
Create `firebase.json.example`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{
      "source": "**",
      "destination": "/index.html"
    }]
  }
}
```

### 3. ComfyUI Setup
1. Install ComfyUI
2. Download required models (CatVTON, IDM-VTON, etc.)
3. Configure workflow files
4. Start ComfyUI server

## 🎯 Usage

### Web Application
1. Navigate to the deployed URL or run locally
2. Register/Login using Firebase Authentication
3. Upload a person image and clothing item
4. Select desired AI model
5. Process the virtual try-on
6. View and download results

### API Usage
```python
import requests

# Upload images for virtual try-on
response = requests.post("http://localhost:8000/api/tryon", 
                        files={
                            "person_image": open("person.jpg", "rb"),
                            "clothing_image": open("cloth.jpg", "rb")
                        },
                        data={"model": "catvton"})
```

## 🔌 API Endpoints

- `POST /api/tryon` - Process virtual try-on
- `GET /api/models` - List available AI models
- `POST /api/upload` - Upload images
- `GET /api/history` - User try-on history
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

## 🤖 AI Models

### CatVTON
- High-quality clothing transfer
- Best for detailed garments
- Processing time: ~30 seconds

### IDM-VTON
- Identity-preserving results
- Good for person consistency
- Processing time: ~25 seconds

### KolorVTON
- Color-aware fitting
- Excellent color matching
- Processing time: ~35 seconds

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all AI models work correctly

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Narayan Kshirsagar**
- GitHub: [@narayankfiles-creator](https://github.com/narayankfiles-creator)
- Email: kshirsagarnarayan06@gmail.com

## 🙏 Acknowledgments

- ComfyUI team for the excellent workflow system
- Flutter team for the amazing framework
- All AI model creators (CatVTON, IDM-VTON, etc.)
- Firebase for hosting and authentication services

## 🐛 Known Issues

- Large model files require significant memory
- Processing times vary based on hardware
- Some clothing types may not work optimally

## 📈 Future Enhancements

- [ ] Mobile app development
- [ ] More AI model integrations
- [ ] Real-time video try-on
- [ ] Social sharing features
- [ ] Advanced user preferences
- [ ] Batch processing capabilities

---

**⭐ If you found this project helpful, please give it a star!**
