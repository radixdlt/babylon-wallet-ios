
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
		isConnectedToAnyConnectorExtension: unimplemented("\(Self.self).isConnectedToAnyConnectorExtension", placeholder: noop.isConnectedToAnyConnectorExtension),
		getDeviceInfo: unimplemented("\(Self.self).getDeviceInfo"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys"),
		newDerivePublicKeys: unimplemented("\(Self.self).newDerivePublicKeys"),
		signTransaction: unimplemented("\(Self.self).signTransaction"),
		newSignTransaction: unimplemented("\(Self.self).newSignTransaction"),
		signPreAuthorization: unimplemented("\(Self.self).signPreAuthorization"),
		signSubintent: unimplemented("\(Self.self).signSubintent"),
		signAuthChallenge: unimplemented("\(Self.self).signAuthChallenge"),
		signAuth: unimplemented("\(Self.self).signAuth"),
		deriveAndDisplayAddress: unimplemented("\(Self.self).deriveAndDisplayAddress")
	)

	static let noop = Self(
		isConnectedToAnyConnectorExtension: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getDeviceInfo: {
			.init(
				id: try! .init(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"),
				model: .nanoS
			)
		},
		derivePublicKeys: { _, _ in
			[]
		},
		newDerivePublicKeys: { _ in [] },
		signTransaction: { _ in [] },
		newSignTransaction: { _ in [] },
		signPreAuthorization: { _ in [] },
		signSubintent: { _ in [] },
		signAuthChallenge: { _ in [] },
		signAuth: { _ in [] },
		deriveAndDisplayAddress: { _, _ in throw NoopError() }
	)
}
