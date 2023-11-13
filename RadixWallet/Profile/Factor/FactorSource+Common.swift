import EngineToolkit

// MARK: - FactorSource.Common
extension FactorSource {
	public struct Common: Sendable, Hashable, Codable {
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

		public var flags: OrderedSet<FactorSourceFlag>

		public init(
			cryptoParameters: FactorSource.CryptoParameters = .babylon,
			flags: OrderedSet<FactorSourceFlag> = [],
			addedOn: Date? = nil,
			lastUsedOn: Date? = nil
		) {
			@Dependency(\.date) var date
			self.cryptoParameters = cryptoParameters
			self.flags = flags
			self.addedOn = addedOn ?? date()
			self.lastUsedOn = lastUsedOn ?? date()
		}
	}
}

extension FactorSource.Common {
	public mutating func flagAsMain() {
		flags.append(.main)
	}

	public static func from(
		cryptoParameters: FactorSource.CryptoParameters = .babylon,
		flags: OrderedSet<FactorSourceFlag> = [],
		addedOn: Date,
		lastUsedOn: Date
	) throws -> Self {
		.init(
			cryptoParameters: cryptoParameters,
			flags: flags,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}
}
