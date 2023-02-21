import ClientPrelude

extension DependencyValues {
	public var engineToolkitClient: EngineToolkitClient {
		get { self[EngineToolkitClient.self] }
		set { self[EngineToolkitClient.self] = newValue }
	}
}
