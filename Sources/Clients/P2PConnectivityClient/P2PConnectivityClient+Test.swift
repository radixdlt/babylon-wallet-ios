import ClientPrelude

#if DEBUG

// MARK: - P2PConnectivityClient + TestDependencyKey
extension P2PConnectivityClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		loadFromProfileAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAndRemoveAll: unimplemented("\(Self.self).disconnectAndRemoveAll"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		storeP2PClient: unimplemented("\(Self.self).storeP2PClient"),
		deleteP2PClientByPassword: unimplemented("\(Self.self).deleteP2PClientByPassword"),
		addP2PWithPassword: unimplemented("\(Self.self).addP2PWithPassword"),
		receiveMessages: unimplemented("\(Self.self).receiveMessages"),
		sendMessage: unimplemented("\(Self.self).sendMessage")
	)
}

extension P2PConnectivityClient {
	static let noop = Self(
		loadFromProfileAndConnectAll: {},
		disconnectAndRemoveAll: {},
		getLocalNetworkAccess: { false },
		getP2PClients: { [] },
		storeP2PClient: { _ in },
		deleteP2PClientByPassword: { _ in },
		addP2PWithPassword: { _ in },
		receiveMessages: { AsyncStream<P2P.RTCIncommingMessageResult>(unfolding: { nil }) },
		sendMessage: { _ in }
	)
}
#endif // DEBUG
