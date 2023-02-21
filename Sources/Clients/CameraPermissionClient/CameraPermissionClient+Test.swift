import ClientPrelude

extension DependencyValues {
	public var cameraPermissionClient: CameraPermissionClient {
		get { self[CameraPermissionClient.self] }
		set { self[CameraPermissionClient.self] = newValue }
	}
}

// MARK: - CameraPermissionClient + TestDependencyKey
extension CameraPermissionClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		getCameraAccess: unimplemented("\(Self.self).getCameraAccess")
	)
}

extension CameraPermissionClient {
	public static let noop = Self(
		getCameraAccess: { false }
	)
}
