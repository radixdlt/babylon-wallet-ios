import AVFoundation
import SwiftUI
import UIKit

// MARK: - UserDefaults.Dependency + DependencyKey
extension CameraPermissionClient: DependencyKey {
	static let liveValue = Self(
		getCameraAccess: {
			await withCheckedContinuation { continuation in
				AVCaptureDevice.requestAccess(for: .video) { access in
					continuation.resume(returning: access)
				}
			}
		}
	)
}
