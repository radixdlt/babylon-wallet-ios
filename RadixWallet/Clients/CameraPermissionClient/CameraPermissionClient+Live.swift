import AVFoundation
import SwiftUI
import UIKit

// MARK: - UserDefaultsClient + DependencyKey
extension CameraPermissionClient: DependencyKey {
	public static let liveValue = Self(
		getCameraAccess: {
			await withCheckedContinuation { continuation in
				AVCaptureDevice.requestAccess(for: .video) { access in
					continuation.resume(returning: access)
				}
			}
		}
	)
}
