import ClientPrelude

extension DependencyValues {
	public var p2pClientsClient: P2PClientsClient {
		get { self[P2PClientsClient.self] }
		set { self[P2PClientsClient.self] = newValue }
	}
}

// MARK: - P2PClientsClient + TestDependencyKey
extension P2PClientsClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let noop = Self(
		getP2PClients: { [] },
		addP2PClient: { _ in },
		deleteP2PClientByPassword: { _ in }
	)
	public static let testValue = Self(
		getP2PClients: unimplemented("\(Self.self).getP2PClients"),
		addP2PClient: unimplemented("\(Self.self).addP2PClient"),
                deleteP2PClientByPassword: unimplemented("\(Self.self).deleteP2PClientByPassword")
	)
}
