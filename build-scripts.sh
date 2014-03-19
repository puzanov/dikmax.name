#!/bin/sh

echo "Building highlight.js..."
python js/highlight.js/tools/build.py bash css haskell javascript markdown sql xml dart
cp dart/packages/browser/dart.js dart/s.js
cat js/highlight.js/build/highlight.pack.js >> dart/s.js

echo "Building main dart..."
dart2js --out=dart/script.dart --minify --output-type=dart dart/main.dart
echo "Building main js..."
dart2js --out=dart/script.dart.js --minify dart/script.dart

echo "Building route-planner dart..."
dart2js --out=dart/script-route-planner.dart --minify --output-type=dart dart/route-planner.dart
echo "Building route-planner js..."
dart2js --out=dart/script-route-planner.dart.js --minify dart/route-planner.dart
