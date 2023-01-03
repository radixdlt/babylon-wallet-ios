import AsyncExtensions
import Dependencies
import Foundation
import P2PModels
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
		addP2PClientWithConnection: unimplemented("\(Self.self).addP2PClientWithConnection"),
		deleteP2PClientByID: unimplemented("\(Self.self).deleteP2PClientByID"),
		getConnectionStatusAsyncSequence: unimplemented("\(Self.self).getConnectionStatusAsyncSequence"),
		getRequestsFromP2PClientAsyncSequence: unimplemented("\(Self.self).getRequestsFromP2PClientAsyncSequence"),
		sendMessageReadReceipt: unimplemented("\(Self.self).sendMessageReadReceipt"),
		sendMessage: unimplemented("\(Self.self).sendMessage"),
		_sendTestMessage: unimplemented("\(Self.self)._sendTestMessage"),
		_debugWebsocketStatusAsyncSequence: unimplemented("\(Self.self)._debugWebsocketStatusAsyncSequence")
	)
}

extension P2PConnectivityClient {
	static let noop = Self(
		getLocalNetworkAccess: { false },
		getP2PClients: { fatalError() },
		addP2PClientWithConnection: { _, _ in },
		deleteP2PClientByID: { _ in },
		getConnectionStatusAsyncSequence: { _ in fatalError() },
		getRequestsFromP2PClientAsyncSequence: { _ in fatalError() },
		sendMessageReadReceipt: { _, _ in },
		sendMessage: { _ in .previewValue },
		_sendTestMessage: { _, _ in },
		_debugWebsocketStatusAsyncSequence: { _ in [].async.eraseToAnyAsyncSequence() }
	)
}

public extension P2PClient {
	static let previewValue = Self(
		connectionPassword: .placeholder,
		displayName: "Placeholder"
	)
}
#endif // DEBUG
