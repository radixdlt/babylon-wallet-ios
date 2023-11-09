
// MARK: - UserDefaults.Dependency
public struct CameraPermissionClient: Sendable {
	public var getCameraAccess: @Sendable () async -> Bool
}
