import ClientPrelude

public extension DependencyValues {
	var cameraPermissionClient: CameraPermissionClient {
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

public extension CameraPermissionClient {
	static let noop = Self(
		getCameraAccess: { false }
	)
}
