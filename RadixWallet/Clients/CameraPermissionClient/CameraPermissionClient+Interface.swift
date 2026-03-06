
// MARK: - UserDefaults.Dependency
struct CameraPermissionClient {
	var getCameraAccess: @Sendable () async -> Bool
}
