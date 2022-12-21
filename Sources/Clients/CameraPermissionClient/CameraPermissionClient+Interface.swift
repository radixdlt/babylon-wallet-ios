import Foundation

// MARK: - UserDefaultsClient
public struct CameraPermissionClient: Sendable {
	public var getCameraAccess: @Sendable () async -> Bool
}
