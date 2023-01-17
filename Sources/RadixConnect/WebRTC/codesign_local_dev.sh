# Codesign the WebRTC framework for local development.
# It is enough to just sign the framework to Run Localy, no need for development or release identity.
xcrun codesign -s - ./WebRTC.xcframework/ios-arm64/WebRTC.framework/WebRTC
xcrun codesign -s - ./WebRTC.xcframework/ios-x86_64_arm64-simulator/WebRTC.framework/WebRTC
xcrun codesign -s - ./WebRTC.xcframework/macos-x86_64_arm64/WebRTC.framework/WebRTC
