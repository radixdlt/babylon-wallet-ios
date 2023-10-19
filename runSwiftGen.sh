#!/bin/sh

# From: https://github.com/SwiftGen/SwiftGen/issues/689
echo "🔮 runSwiftGen.sh - Running SwiftGen 🏃‍♂️"

cd ${BUILD_DIR%Build/*}SourcePackages/checkouts/SwiftGen

# This is magic
/usr/bin/xcrun --sdk macosx swift run swiftgen config run --config $SRCROOT/swiftgen.yml

# If this stops working, Apple has twisted the system again to break stuff.
# I found this solution by combining these two comments
# https://github.com/SwiftGen/SwiftGen/issues/689#issuecomment-630040692
# https://github.com/SwiftGen/SwiftGen/issues/689#issuecomment-622341803
# Good luck...

echo "🔮 runSwiftGen.sh - Done ✅"