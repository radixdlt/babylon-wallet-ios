
extension DependencyValues {
	var cameraPermissionClient: CameraPermissionClient {
		get { self[CameraPermissionClient.self] }
		set { self[CameraPermissionClient.self] = newValue }
	}
}

// MARK: - CameraPermissionClient + TestDependencyKey
extension CameraPermissionClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		getCameraAccess: unimplemented("\(Self.self).getCameraAccess", placeholder: noop.getCameraAccess)
	)
}

extension CameraPermissionClient {
	static let noop = Self(
		getCameraAccess: { false }
	)
}
