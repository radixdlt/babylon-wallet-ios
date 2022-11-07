import Dependencies
import KeychainClient

// TODO: `KeychainClient` package should declare these conformances itself,
// but it's currently in swift-profile and I don't want to create even further chained
// PRs during this big refactor.

extension KeychainClient: DependencyKey {
	public typealias Value = KeychainClient

	public static let liveValue = Self.live(
		accessibility: .whenPasscodeSetThisDeviceOnly,
		authenticationPolicy: .biometryCurrentSet
	)
}
