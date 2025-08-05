# Aham AI Chat App - APK Installation Guide

## 📱 About the App
**Aham** is an AI-powered chat application that supports multiple AI models including Gemini, GPT, Claude, and more. The app features:
- Multiple AI model support (Gemini 2.5 Flash, GPT 4.1, OpenAI O3, DeepSeek R1, etc.)
- System-based dark/light theme (follows device settings)
- File attachments and image processing
- Web search integration
- PDF generation and text-to-speech capabilities
- Modern Material Design UI

## 📥 Installation Instructions

### APK File Details
- **Main File**: `aham-app-release.apk` *(latest with green theme & modern button)*
- **Version 3**: `aham-app-release-v3.apk` *(same as above)*
- **Previous**: `aham-app-release-v2.apk` *(warm cream theme)*
- **Size**: ~25.7 MB
- **Version**: 1.0.0+1
- **Target SDK**: Android API 35 (Android 15)
- **Minimum SDK**: As per Flutter 3.24.5 requirements

### Installation Steps

1. **Download the APK**
   - Download `aham-app-release.apk` from this repository (latest with green theme & modern button)

2. **Enable Unknown Sources** (if not already enabled)
   - Go to Settings → Security → Unknown Sources
   - Or Settings → Apps & notifications → Advanced → Special app access → Install unknown apps
   - Enable installation from your file manager or browser

3. **Install the APK**
   - Open your file manager
   - Navigate to the downloaded APK file
   - Tap on `aham-app-release.apk`
   - Follow the installation prompts
   - Tap "Install" when prompted

4. **Launch the App**
   - Find "Aham" in your app drawer
   - Tap to launch the application

## ⚠️ Important Notes

### Security Considerations
- This APK is signed with debug keys (for testing purposes)
- For production use, proper signing with release keys is recommended
- **API Keys Warning**: The current build contains hardcoded API keys which should be secured in production

### Permissions
The app requires the following permissions:
- Internet access (for AI model communication)
- Network state access
- File access (for attachments)
- Camera/Gallery access (for image uploads)

### Compatibility
- Compatible with Android devices supporting API level as per Flutter 3.24.5
- Tested build environment: Android SDK 35, Build Tools 35.0.0
- Java/Kotlin compatible versions included

## 🔧 Build Information
- **Flutter Version**: 3.24.5
- **Android SDK**: API 35
- **Build Tools**: 35.0.0
- **Java Version**: 21
- **Built on**: Ubuntu 25.04

## 📱 Features Overview
- **AI Models**: Gemini 2.5 Flash, GPT 4.1 Mini/Large, OpenAI O3, DeepSeek R1, SearchGPT, Grok variants, Claude 4 Sonnet
- **Theme**: Automatic system-based theme switching (removed manual toggle)
- **UI**: Grey user message bubbles (updated from black)
- **Design**: Fresh green theme (#ECFAE5 background, #DDF6D2 buttons)
- **User Messages**: Dark grey bubbles (#222831) for better contrast
- **New Chat Button**: Modern design with gradient, shadow, and icon container
- **File Support**: Document attachments, image uploads, archive processing
- **Additional**: PDF generation, TTS, web search integration

## 🚨 Security Recommendations for Production
1. Regenerate and secure all API keys
2. Implement proper release signing
3. Add certificate pinning for API calls
4. Implement input validation and sanitization
5. Add proper error handling and logging

## 📝 Changelog

### Version 3 (aham-app-release-v3.apk) - **LATEST**
- ✅ **Fresh Green Theme**: Changed to light green background (#ECFAE5)
- ✅ **Green Buttons**: Updated to light green (#DDF6D2) for consistency
- ✅ **Dark User Messages**: Changed user bubbles to dark grey (#222831) for better contrast
- ✅ **Modern New Chat Button**: Redesigned with gradient, shadow, elevated icon container
- ✅ **Enhanced Visual Appeal**: Subtle borders, improved spacing, and modern aesthetics

### Version 2 (aham-app-release-v2.apk)
- ✅ **Light Theme Update**: Changed background from white to warm cream (#FAF7F3)
- ✅ **Button Colors**: Updated button background to warm beige (#F0E4D3) with black text
- ✅ **New Chat Button**: Redesigned as smaller, rounded button with "New Chat" label
- ✅ **AppBar**: Updated to match new background color
- ✅ **Cards**: Updated card background to match new button color

### Version 1 (aham-app-release.apk)
- ✅ System-based theme switching (removed manual dark mode toggle)
- ✅ Grey user message bubbles (changed from black)
- ✅ All original functionality preserved

---
*Built with Flutter 3.24.5 • Created for testing and evaluation purposes*