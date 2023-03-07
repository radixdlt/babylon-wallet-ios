import ClientPrelude

#if DEBUG

extension RadixConnectClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		loadFromProfileAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAndRemoveAll: unimplemented("\(Self.self).disconnectAndRemoveAll"),
		disconnectAll: unimplemented("\(Self.self).disconnectAll"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		storeP2PClient: unimplemented("\(Self.self).storeP2PClient"),
		deleteP2PClientByPassword: unimplemented("\(Self.self).deleteP2PClientByPassword"),
		addP2PWithPassword: unimplemented("\(Self.self).addP2PWithPassword"),
		receiveMessages: unimplemented("\(Self.self).receiveMessages"),
		sendMessage: unimplemented("\(Self.self).sendMessage")
	)
}

extension RadixConnectClient {
	static let noop = Self(
		loadFromProfileAndConnectAll: {},
		disconnectAndRemoveAll: {},
		disconnectAll: {},
		getLocalNetworkAccess: { false },
		getP2PClients: { [] },
		storeP2PClient: { _ in },
		deleteP2PClientByPassword: { _ in },
		addP2PWithPassword: { _ in },
		receiveMessages: { AsyncStream<P2P.RTCIncomingMessageResult>(unfolding: { nil }) },
		sendMessage: { _ in }
	)
}
#endif // DEBUG
