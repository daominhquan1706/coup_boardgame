#!/bin/bash

# Flutter Performance Optimization Build Script
# This script builds the Flutter app with optimizations for web deployment

echo "🚀 Starting optimized Flutter build process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "Not in a Flutter project directory"
    exit 1
fi

print_status "Cleaning previous build artifacts..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

print_status "Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

print_status "Analyzing code for potential issues..."
flutter analyze

print_status "Running tests..."
flutter test

print_status "Building for web with optimizations..."

# Build with optimizations
flutter build web \
    --web-renderer canvaskit \
    --dart-define=FLUTTER_WEB_USE_SKIA=true \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false \
    --release \
    --tree-shake-icons \
    --source-maps \
    --pwa-strategy=offline-first

# Check if build was successful
if [ $? -eq 0 ]; then
    print_status "✅ Build completed successfully!"
    
    # Calculate build sizes
    BUILD_DIR="build/web"
    if [ -d "$BUILD_DIR" ]; then
        print_status "📊 Build size analysis:"
        echo "Total build size: $(du -sh $BUILD_DIR | cut -f1)"
        echo "Main bundle size: $(du -sh $BUILD_DIR/main.dart.js | cut -f1)"
        echo "Flutter service worker: $(du -sh $BUILD_DIR/flutter_service_worker.js | cut -f1)"
        
        # Check for large assets
        echo ""
        print_status "🔍 Largest files in build:"
        find $BUILD_DIR -type f -size +100k -exec ls -lh {} \; | sort -k5 -hr | head -10
        
        # Optimization recommendations
        echo ""
        print_status "💡 Optimization recommendations:"
        
        # Check for unoptimized images
        if find $BUILD_DIR -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | head -1 | grep -q .; then
            print_warning "Consider optimizing images with tools like imagemin"
        fi
        
        # Check bundle size
        MAIN_SIZE=$(stat -c%s "$BUILD_DIR/main.dart.js" 2>/dev/null || stat -f%z "$BUILD_DIR/main.dart.js" 2>/dev/null || echo "0")
        if [ "$MAIN_SIZE" -gt 1048576 ]; then # 1MB
            print_warning "Main bundle is large (>1MB). Consider code splitting."
        fi
        
        print_status "🌐 Web deployment ready!"
        echo "Build output: $BUILD_DIR"
        echo ""
        echo "To serve locally:"
        echo "  cd $BUILD_DIR && python -m http.server 8000"
        echo ""
        echo "To deploy to Firebase:"
        echo "  firebase deploy --only hosting"
        echo ""
        echo "To deploy to GitHub Pages:"
        echo "  Copy contents of $BUILD_DIR to your GitHub Pages repository"
        
    else
        print_error "Build directory not found"
        exit 1
    fi
    
else
    print_error "❌ Build failed!"
    exit 1
fi

# Optional: Run lighthouse audit if available
if command -v lighthouse &> /dev/null; then
    print_status "🔍 Running Lighthouse audit..."
    echo "You can run: lighthouse http://localhost:8000 --output=html --output-path=./lighthouse-report.html"
fi

print_status "🎉 Optimization complete!"