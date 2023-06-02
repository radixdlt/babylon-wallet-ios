import Prelude

// MARK: - UnsecuredEntityControl
/// Basic security control of an unsecured entity. When said entity
/// is "securified" it will no longer be controlled by this `UnsecuredEntityControl`
/// but rather by an `AccessControl`. It is a name space holding the
/// single factor instance which was used to create
public struct UnsecuredEntityControl:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// The factor instance which was used to create this unsecured entity, which
	/// also controls this entity and is used for signign transactions.
	public let transactionSigning: HierarchicalDeterministicFactorInstance

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: HierarchicalDeterministicFactorInstance?

	public init(
		transactionSigning: HierarchicalDeterministicFactorInstance,
		authenticationSigning: HierarchicalDeterministicFactorInstance? = nil
	) {
		self.transactionSigning = transactionSigning
		self.authenticationSigning = authenticationSigning
	}
}

extension UnsecuredEntityControl {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			transactionSigning: container.decode(
				HierarchicalDeterministicFactorInstance.self,
				forKey: .transactionSigning
			),
			authenticationSigning: container.decodeIfPresent(
				HierarchicalDeterministicFactorInstance.self,
				forKey: .authenticationSigning
			)
		)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(transactionSigning, forKey: .transactionSigning)
		try container.encodeIfPresent(authenticationSigning, forKey: .authenticationSigning)
	}

	private enum CodingKeys: String, CodingKey {
		case transactionSigning
		case authenticationSigning
	}
}

extension UnsecuredEntityControl {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"transactionSigning": transactionSigning,
				"authenticationSigning": authenticationSigning,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		transactionSigning: \(transactionSigning)
		authenticationSigning: \(authenticationSigning)
		"""
	}
}
