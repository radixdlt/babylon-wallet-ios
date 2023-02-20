import ClientPrelude

extension UseFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue = Self(
		onDeviceHDPublicKey: { request in

			let privateKey = try request.hdRoot.derivePrivateKey(
				path: request.derivationPath,
				curve: request.curve
			)

			let publicKey = try privateKey.publicKey().intoEngine()
			return publicKey
		}
	)
}
