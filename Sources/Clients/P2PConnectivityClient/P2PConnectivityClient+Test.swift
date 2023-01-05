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
		_debugWebsocketStatusAsyncSequence: unimplemented("\(Self.self)._debugWebsocketStatusAsyncSequence"),
		_debugDataChannelStatusAsyncSequence: unimplemented("\(Self.self)._debugDataChannelStatusAsyncSequence")
	)
}

extension P2PConnectivityClient {
	static let noop = Self(
		getLocalNetworkAccess: { false },
		getP2PClients: { [].async.eraseToAnyAsyncSequence() },
		addP2PClientWithConnection: { _ in },
		deleteP2PClientByID: { _ in },
		getConnectionStatusAsyncSequence: { _ in [].async.eraseToAnyAsyncSequence() },
		getRequestsFromP2PClientAsyncSequence: { _ in [].async.eraseToAnyAsyncSequence() },
		sendMessageReadReceipt: { _, _ in },
		sendMessage: { _ in .previewValue },
		_sendTestMessage: { _, _ in },
		_debugWebsocketStatusAsyncSequence: { _ in [].async.eraseToAnyAsyncSequence() },
		_debugDataChannelStatusAsyncSequence: { _ in [].async.eraseToAnyAsyncSequence() }
	)
}

public extension P2PClient {
	static let previewValue = Self(
		connectionPassword: .placeholder,
		displayName: "Placeholder"
	)
}
#endif // DEBUG
