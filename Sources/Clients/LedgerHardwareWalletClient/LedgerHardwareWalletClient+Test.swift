import ClientPrelude
import Cryptography

extension DependencyValues {
	public var ledgerHardwareWalletClient: LedgerHardwareWalletClient {
		get { self[LedgerHardwareWalletClient.self] }
		set { self[LedgerHardwareWalletClient.self] = newValue }
	}
}

extension FactorSource.ID {
	static let mocked = try! Self(hexCodable: .init(hex: String(repeating: "deadbeef", count: 8)))
}

// MARK: - LedgerHardwareWalletClient + TestDependencyKey
extension LedgerHardwareWalletClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		isConnectedToAnyConnectorExtension: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getDeviceInfo: {
			.init(
				id: .mocked,
				model: .nanoS
			)
		},
		importOlympiaDevice: { _ in
			.init(
				id: .mocked,
				model: .nanoS,
				derivedPublicKeys: []
			)
		},
		deriveCurve25519PublicKey: { _, _ in
			Curve25519.Signing.PrivateKey().publicKey
		}
	)

	public static let testValue = Self(
		isConnectedToAnyConnectorExtension: unimplemented("\(Self.self).isConnectedToAnyConnectorExtension"),
		getDeviceInfo: unimplemented("\(Self.self).getDeviceInfo"),
		importOlympiaDevice: unimplemented("\(Self.self).importOlympiaDevice"),
		deriveCurve25519PublicKey: unimplemented("\(Self.self).deriveCurve25519PublicKey")
	)
}
