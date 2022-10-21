import ComposableArchitecture
import Foundation

// MARK: - GatewayAPIClientKey
public enum GatewayAPIClientKey: DependencyKey {}
public extension GatewayAPIClientKey {
	typealias Value = GatewayAPIClient
	static let liveValue = GatewayAPIClient.live
	static let testValue = GatewayAPIClient.mock()
}

public extension DependencyValues {
	var gatewayAPIClient: GatewayAPIClient {
		get { self[GatewayAPIClientKey.self] }
		set { self[GatewayAPIClientKey.self] = newValue }
	}
}
