import AsyncExtensions
import Dependencies
import Foundation
import Profile
import SharedModels
import XCTestDynamicOverlay

#if DEBUG

// MARK: - P2PConnectivityClient + TestDependencyKey
extension P2PConnectivityClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		getP2PConnections: unimplemented("\(Self.self).getP2PConnections"),
		addP2PClientWithConnection: unimplemented("\(Self.self).addP2PClientWithConnection"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getConnectionStatusAsyncSequence: unimplemented("\(Self.self).getConnectionStatusAsyncSequence"),
		getRequestsFromP2PClientAsyncSequence: unimplemented("\(Self.self).getRequestsFromP2PClientAsyncSequence"),
		sendMessageReadReceipt: unimplemented("\(Self.self).sendMessageReadReceipt"),
		sendMessage: unimplemented("\(Self.self).sendMessage"),
		_sendTestMessage: unimplemented("\(Self.self)._sendTestMessage")
	)
}

extension P2PConnectivityClient {
	static let noop = Self(
		getLocalNetworkAccess: { false },
		getP2PClients: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getP2PConnections: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		addP2PClientWithConnection: { _, _ in },
		deleteP2PClientByID: { _ in },
		getConnectionStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getRequestsFromP2PClientAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendMessageReadReceipt: { _, _ in },
		sendMessage: { _ in .placeholder },
		_sendTestMessage: { _, _ in }
	)
}

public extension P2PClient {
	static let placeholder = try! Self(
		displayName: "Placeholder",
		connectionPassword: Data(hexString: "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")
	)
}
#endif // DEBUG
