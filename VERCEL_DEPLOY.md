# Deploying to Vercel

## ⚠️ Important Note

**Flutter web apps are better suited for Firebase Hosting, Netlify, or GitHub Pages** because Vercel doesn't have built-in Flutter support. However, you can still deploy to Vercel by pre-building the app.

## 🚀 Option 1: Deploy to Vercel (Manual Build)

Since Vercel doesn't support Flutter builds in their cloud environment, you need to build locally and deploy the static files.

### Step 1: Build Your Flutter Web App Locally

```bash
# Make sure you're in the project directory
cd /home/user/Crossfit

# Build for web (production mode)
flutter build web --release
```

This creates a `build/web` folder with all the static files.

### Step 2: Deploy to Vercel

**Option A: Using Vercel CLI**

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy (from project root)
vercel --prod
```

**Option B: Using Vercel Dashboard**

1. Go to [vercel.com](https://vercel.com)
2. Click "Add New Project"
3. Import your Git repository
4. Configure:
   - **Framework Preset**: Other
   - **Build Command**: `flutter build web --release` (won't work on Vercel cloud)
   - **Output Directory**: `build/web`
   - **Install Command**: Leave empty

5. Since Vercel can't run Flutter, you need to:
   - Build locally: `flutter build web --release`
   - Deploy only the `build/web` folder
   - Use Vercel CLI or drag & drop in dashboard

## 🔥 Option 2: Deploy to Firebase Hosting (RECOMMENDED)

Firebase Hosting is **much better** for Flutter web apps and integrates perfectly with your existing Firebase backend.

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Initialize Firebase Hosting

```bash
# In your project directory
firebase init hosting

# Choose:
# - Select your Firebase project
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Set up automatic builds with GitHub: No (for now)
```

### Step 4: Build and Deploy

```bash
# Build the web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

Your app will be live at: `https://your-project-id.web.app`

### Step 5: Custom Domain (Optional)

In Firebase Console → Hosting → Add custom domain

## 📦 Option 3: Netlify (Also Good Alternative)

### Step 1: Create netlify.toml

```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Step 2: Deploy

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build locally
flutter build web --release

# Deploy
netlify deploy --prod --dir=build/web
```

## 🐛 Troubleshooting Vercel 404 Error

The error you're seeing happens because:

1. **Vercel can't build Flutter apps** - They don't have Flutter installed in their build environment
2. **No static files found** - Vercel is looking for files that don't exist because the build failed

### Solutions:

**Quick Fix (for Vercel):**

```bash
# 1. Build locally
flutter build web --release

# 2. Deploy only the build folder using Vercel CLI
cd build/web
vercel --prod
```

**Better Solution:**
Use Firebase Hosting (recommended) or Netlify instead. Both support Flutter web apps better than Vercel.

## ⚡ CI/CD with GitHub Actions (Any Platform)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Flutter Web

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - run: flutter pub get
      - run: flutter build web --release

      # For Firebase
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

## 🎯 Recommended Deployment Flow

1. **Development**: `flutter run -d chrome`
2. **Build**: `flutter build web --release`
3. **Deploy**:
   - **Best**: Firebase Hosting (`firebase deploy`)
   - **Good**: Netlify
   - **Possible**: Vercel (requires local build)

## 📝 Pre-Deployment Checklist

- [ ] Firebase configuration is set up (`firebase_options.dart`)
- [ ] All Firebase services are enabled (Auth, Firestore, Storage)
- [ ] Firestore security rules are configured
- [ ] Build completes without errors: `flutter build web --release`
- [ ] Test locally: `cd build/web && python3 -m http.server 8000`
- [ ] Environment variables configured (if any)

## 🔐 Important: Firebase Config

Make sure your `lib/firebase_options.dart` has the correct **web** configuration with your production Firebase project credentials.

## 💡 Performance Tips

After deploying, optimize performance:

1. **Enable Compression** (Firebase does this automatically)
2. **Use CDN** (Firebase/Netlify/Vercel all provide this)
3. **Cache Static Assets** (configured in `vercel.json`)
4. **Lazy Load Images** (already implemented in the app)

---

**Quick Answer for Your Error:**

Your Vercel deployment failed because Vercel can't build Flutter apps.

**Fix:**
```bash
# Build locally
flutter build web --release

# Then deploy with Vercel CLI from build/web folder
cd build/web
vercel --prod
```

**Or switch to Firebase Hosting (recommended):**
```bash
firebase init hosting
flutter build web --release
firebase deploy --only hosting
```

Good luck! 🚀
