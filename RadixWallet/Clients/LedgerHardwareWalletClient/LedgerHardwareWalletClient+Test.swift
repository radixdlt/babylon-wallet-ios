
extension DependencyValues {
	public var ledgerHardwareWalletClient: LedgerHardwareWalletClient {
		get { self[LedgerHardwareWalletClient.self] }
		set { self[LedgerHardwareWalletClient.self] = newValue }
	}
}

// MARK: - LedgerHardwareWalletClient + TestDependencyKey
extension LedgerHardwareWalletClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		isConnectedToAnyConnectorExtension: unimplemented("\(Self.self).isConnectedToAnyConnectorExtension"),
		getDeviceInfo: unimplemented("\(Self.self).getDeviceInfo"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys"),
		signTransaction: unimplemented("\(Self.self).signTransaction"),
		signAuthChallenge: unimplemented("\(Self.self).signAuthChallenge"),
		deriveAndDisplayAddress: unimplemented("\(Self.self).deriveAndDisplayAddress")
	)

	public static let noop = Self(
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
		signTransaction: { _ in [] },
		signAuthChallenge: { _ in [] },
		deriveAndDisplayAddress: { _, _ in throw NoopError() }
	)
}
