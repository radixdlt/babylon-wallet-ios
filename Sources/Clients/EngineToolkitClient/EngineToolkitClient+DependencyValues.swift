import ClientPrelude

public extension DependencyValues {
	var engineToolkitClient: EngineToolkitClient {
		get { self[EngineToolkitClient.self] }
		set { self[EngineToolkitClient.self] = newValue }
	}
}
