
#if DEBUG

extension RadixConnectClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		loadP2PLinksAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAll: unimplemented("\(Self.self).disconnectAll"),
		connectToP2PLinks: unimplemented("\(Self.self).connectToP2PLinks"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
		getP2PLinksWithConnectionStatusUpdates: unimplemented("\(Self.self).getP2PLinksWithConnectionStatusUpdates"),
		idsOfConnectedPeerConnections: unimplemented("\(Self.self).idsOfConnectedPeerConnections"),
		updateOrAddP2PLink: unimplemented("\(Self.self).updateOrAddP2PLink"),
		deleteP2PLinkByPassword: unimplemented("\(Self.self).deleteP2PLinkByPassword"),
		connectP2PLink: unimplemented("\(Self.self).connectP2PLink"),
		receiveMessages: unimplemented("\(Self.self).receiveMessages"),
		sendResponse: unimplemented("\(Self.self).sendResponse"),
		sendRequest: unimplemented("\(Self.self).sendRequest"),
		handleDappDeepLink: unimplemented("\(Self.self).sendRequest"),
		updateP2PLinkName: unimplemented("\(Self.self).updateP2PLinkName")
	)
}

extension RadixConnectClient {
	static let noop = Self(
		loadP2PLinksAndConnectAll: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		disconnectAll: {},
		connectToP2PLinks: { _ in },
		getLocalNetworkAccess: { false },
		getP2PLinks: { [] },
		getP2PLinksWithConnectionStatusUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		idsOfConnectedPeerConnections: { [] },
		updateOrAddP2PLink: { _ in },
		deleteP2PLinkByPassword: { _ in },
		connectP2PLink: { _ in },
		receiveMessages: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendResponse: { _, _ in },
		sendRequest: { _, _ in 0 },
		handleDappDeepLink: { _ in },
		updateP2PLinkName: { _ in }
	)
}
#endif // DEBUG
