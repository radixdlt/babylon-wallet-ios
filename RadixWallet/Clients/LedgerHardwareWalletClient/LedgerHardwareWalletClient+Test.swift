
extension DependencyValues {
	var ledgerHardwareWalletClient: LedgerHardwareWalletClient {
		get { self[LedgerHardwareWalletClient.self] }
		set { self[LedgerHardwareWalletClient.self] = newValue }
	}
}

// MARK: - LedgerHardwareWalletClient + TestDependencyKey
extension LedgerHardwareWalletClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		hasAnyLinkedConnector: unimplemented("\(Self.self).hasAnyLinkedConnector", placeholder: noop.hasAnyLinkedConnector),
		getDeviceInfo: unimplemented("\(Self.self).getDeviceInfo"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys"),
		signTransaction: unimplemented("\(Self.self).signTransaction"),
		signSubintent: unimplemented("\(Self.self).signSubintent"),
		signAuth: unimplemented("\(Self.self).signAuth"),
		deriveAndDisplayAddress: unimplemented("\(Self.self).deriveAndDisplayAddress")
	)

	static let noop = Self(
		hasAnyLinkedConnector: { false },
		getDeviceInfo: {
			.init(
				id: try! .init(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"),
				model: .nanoS
			)
		},
		derivePublicKeys: { _ in [] },
		signTransaction: { _ in [] },
		signSubintent: { _ in [] },
		signAuth: { _ in [] },
		deriveAndDisplayAddress: { _, _ in throw NoopError() }
	)
}
