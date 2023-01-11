import P2PModels
import Prelude
import Profile
import SharedModels
import XCTestDynamicOverlay

#if DEBUG

// MARK: - P2PConnectivityClient + TestDependencyKey
extension P2PConnectivityClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		loadFromProfileAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAndRemoveAll: unimplemented("\(Self.self).disconnectAndRemoveAll"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PClientIDs: unimplemented("\(Self.self).getP2PClientIDs"),
		getP2PClientsByIDs: unimplemented("\(Self.self).getP2PClientsByIDs"),
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
		loadFromProfileAndConnectAll: {},
		disconnectAndRemoveAll: {},
		getLocalNetworkAccess: { false },
		getP2PClientIDs: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getP2PClientsByIDs: { _ in .init() },
		addP2PClientWithConnection: { _ in },
		deleteP2PClientByID: { _ in },
		getConnectionStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getRequestsFromP2PClientAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendMessageReadReceipt: { _, _ in },
		sendMessage: { _ in .previewValue },
		_sendTestMessage: { _, _ in },
		_debugWebsocketStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		_debugDataChannelStatusAsyncSequence: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}

public extension P2PClient {
	static let previewValue = Self(
		connectionPassword: .placeholder,
		displayName: "PreviewValue"
	)
}
#endif // DEBUG
