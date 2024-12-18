
#if DEBUG

extension RadixConnectClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		loadP2PLinksAndConnectAll: noop.loadP2PLinksAndConnectAll,
		disconnectAll: unimplemented("\(Self.self).disconnectAll"),
		connectToP2PLinks: unimplemented("\(Self.self).connectToP2PLinks"),
		getLocalNetworkAccess: noop.getLocalNetworkAccess,
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
		getP2PLinksWithConnectionStatusUpdates: noop.getP2PLinksWithConnectionStatusUpdates,
		idsOfConnectedPeerConnections: noop.idsOfConnectedPeerConnections,
		updateOrAddP2PLink: unimplemented("\(Self.self).updateOrAddP2PLink"),
		deleteP2PLinkByPassword: unimplemented("\(Self.self).deleteP2PLinkByPassword"),
		connectP2PLink: unimplemented("\(Self.self).connectP2PLink"),
		receiveMessages: noop.receiveMessages,
		sendResponse: unimplemented("\(Self.self).sendResponse"),
		sendRequest: unimplemented("\(Self.self).sendRequest"),
		handleDappDeepLink: unimplemented("\(Self.self).sendRequest"),
		startNotifyingConnectorWithAccounts: unimplemented("\(Self.self).startNotifyingConnectorWithAccounts")
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
		startNotifyingConnectorWithAccounts: {}
	)
}
#endif // DEBUG
