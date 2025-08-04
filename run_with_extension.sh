#!/bin/bash

echo "Starting Voo Logger DevTools Extension..."

# Build the extension
cd extension
flutter build web

# Start a simple HTTP server for the extension
echo "Extension available at: http://localhost:9101"
cd build/web
python3 -m http.server 9101 &
SERVER_PID=$!

# Go back to example
cd ../../../example

echo "Starting example app..."
echo "Once DevTools opens, you can manually load the extension from http://localhost:9101"
flutter run -d chrome

# Cleanup
kill $SERVER_PID