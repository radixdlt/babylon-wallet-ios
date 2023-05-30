import Prelude

// MARK: - FactorSource.Common
extension FactorSource {
	public struct Common: Sendable, Hashable, Codable {
		/// Canonical identifier which uniquely identifies this factor source
		public let id: FactorSourceID

		/// Curve/Derivation scheme
		public let cryptoParameters: FactorSource.CryptoParameters

		/// When this factor source for originally added by the user.
		public let addedOn: Date

		/// Date of last usage of this factor source
		///
		/// This is the only mutable property, it is mutable
		/// since we will update it every time this FactorSource
		/// is used.
		public var lastUsedOn: Date

		public init(
			id: FactorSourceID,
			cryptoParameters: FactorSource.CryptoParameters = .babylon,
			addedOn: Date? = nil,
			lastUsedOn: Date? = nil
		) {
			@Dependency(\.date) var date
			self.id = id
			self.cryptoParameters = cryptoParameters
			self.addedOn = addedOn ?? date()
			self.lastUsedOn = lastUsedOn ?? date()
		}
	}
}

extension FactorSource.Common {
	public static func from(
		factorSourceKind: FactorSourceKind,
		hdRoot: HD.Root,
		cryptoParameters: FactorSource.CryptoParameters = .babylon,
		addedOn: Date,
		lastUsedOn: Date
	) throws -> Self {
		try .init(
			id: FactorSource.id(
				fromRoot: hdRoot,
				factorSourceKind: factorSourceKind
			),
			cryptoParameters: cryptoParameters,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public static func from(
		factorSourceKind: FactorSourceKind,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		cryptoParameters: FactorSource.CryptoParameters = .babylon,
		addedOn: Date,
		lastUsedOn: Date
	) throws -> Self {
		try Self.from(
			factorSourceKind: factorSourceKind,
			hdRoot: mnemonicWithPassphrase.hdRoot(),
			cryptoParameters: cryptoParameters,
			addedOn: addedOn, lastUsedOn: lastUsedOn
		)
	}
}
