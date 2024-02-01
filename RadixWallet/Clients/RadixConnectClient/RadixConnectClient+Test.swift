
#if DEBUG

extension RadixConnectClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		loadFromProfileAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAll: unimplemented("\(Self.self).disconnectAll"),
		connectToP2PLinks: unimplemented("\(Self.self).connectToP2PLinks"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
		getP2PLinksWithConnectionStatusUpdates: unimplemented("\(Self.self).getP2PLinksWithConnectionStatusUpdates"),
		idsOfConnectedPeerConnections: unimplemented("\(Self.self).idsOfConnectedPeerConnections"),
		storeP2PLink: unimplemented("\(Self.self).storeP2PLink"),
		deleteP2PLinkByPassword: unimplemented("\(Self.self).deleteP2PLinkByPassword"),
		addP2PWithPassword: unimplemented("\(Self.self).addP2PWithPassword"),
		receiveMessages: unimplemented("\(Self.self).receiveMessages"),
		sendResponse: unimplemented("\(Self.self).sendResponse"),
		sendRequest: unimplemented("\(Self.self).sendRequest")
	)
}

extension RadixConnectClient {
	static let noop = Self(
		loadFromProfileAndConnectAll: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		disconnectAll: {},
		connectToP2PLinks: { _ in },
		getLocalNetworkAccess: { false },
		getP2PLinks: { [] },
		getP2PLinksWithConnectionStatusUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		idsOfConnectedPeerConnections: { [] },
		storeP2PLink: { _ in },
		deleteP2PLinkByPassword: { _ in },
		addP2PWithPassword: { _ in },
		receiveMessages: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendResponse: { _, _ in },
		sendRequest: { _, _ in 0 }
	)
}
#endif // DEBUG
