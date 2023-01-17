# WebRTC framework

This is the binary for WebRTC framework downloaded from [WebRTC](https://github.com/stasel/WebRTC).

Latest version: [M109](https://github.com/stasel/WebRTC/releases/tag/109.0.0)

Xcode requires WebRTC to be signed to be able integrate it. Therefore we do download the WebRTC binary, sign it, and integrate it in our project.

To update to a new version:
- Download the binary from [WebRTC](https://github.com/stasel/WebRTC).
- Replace the old binary with a new one.
- Run `codesign_local_dev` to sign the framework.
