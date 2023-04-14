import ClientPrelude

#if DEBUG

extension RadixConnectClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		loadFromProfileAndConnectAll: unimplemented("\(Self.self).loadFromProfileAndConnectAll"),
		disconnectAndRemoveAll: unimplemented("\(Self.self).disconnectAndRemoveAll"),
		disconnectAll: unimplemented("\(Self.self).disconnectAll"),
		getLocalNetworkAccess: unimplemented("\(Self.self).getLocalNetworkAccess"),
		getP2PLinks: unimplemented("\(Self.self).getP2PLinks"),
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
		loadFromProfileAndConnectAll: {},
		disconnectAndRemoveAll: {},
		disconnectAll: {},
		getLocalNetworkAccess: { false },
		getP2PLinks: { [] },
		storeP2PLink: { _ in },
		deleteP2PLinkByPassword: { _ in },
		addP2PWithPassword: { _ in },
		receiveMessages: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		sendResponse: { _, _ in },
		sendRequest: { _, _ in }
	)
}
#endif // DEBUG
