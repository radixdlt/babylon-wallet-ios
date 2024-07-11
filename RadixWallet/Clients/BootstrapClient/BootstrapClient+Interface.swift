// MARK: - BootstrapClient
struct BootstrapClient: Sendable {
	var bootstrap: Bootstrap
}

// MARK: BootstrapClient.Bootstrap
extension BootstrapClient {
	typealias Bootstrap = @Sendable () -> Void
}

extension DependencyValues {
	var bootstrapClient: BootstrapClient {
		get { self[BootstrapClient.self] }
		set { self[BootstrapClient.self] = newValue }
	}
}
