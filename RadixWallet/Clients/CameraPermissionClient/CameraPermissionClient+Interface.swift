
// MARK: - UserDefaults.Dependency
struct CameraPermissionClient: Sendable {
	var getCameraAccess: @Sendable () async -> Bool
}
