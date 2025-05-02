// MARK: - BootstrapClient
struct BootstrapClient: Sendable {
	var bootstrap: Bootstrap
	var configureSceneDelegate: ConfigureSceneDelegate
}

// MARK: BootstrapClient.Bootstrap
extension BootstrapClient {
	typealias Bootstrap = @Sendable () -> Void
	typealias ConfigureSceneDelegate = (SceneDelegateManager) -> Void
}

extension DependencyValues {
	var bootstrapClient: BootstrapClient {
		get { self[BootstrapClient.self] }
		set { self[BootstrapClient.self] = newValue }
	}
}
