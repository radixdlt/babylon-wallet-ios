import Dependencies
import KeychainClient

// MARK: - KeychainClient + TestDependencyKey
// TODO: `KeychainClient` package should declare these conformances itself,
// but it's currently in swift-profile and I don't want to create even further chained
// PRs during this big refactor.
#if DEBUG
extension KeychainClient: TestDependencyKey {
	public static let testValue = KeychainClient.unimplemented
}
#endif
public extension DependencyValues {
	var keychainClient: KeychainClient {
		get { self[KeychainClient.self] }
		set { self[KeychainClient.self] = newValue }
	}
}
