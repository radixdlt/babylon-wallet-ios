import AVKit
import Dependencies
import Foundation

// MARK: - UserDefaultsClient + DependencyKey
extension CameraPermissionClient: DependencyKey {
	public static let liveValue = Self(
		getCameraAccess: {
			await withUnsafeContinuation { continuation in
				AVCaptureDevice.requestAccess(for: .video) { access in
					continuation.resume(returning: access)
				}
			}
		}
	)
}
