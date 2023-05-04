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
	public let transactionSigning: FactorInstance

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: FactorInstance?

	public init(
		transactionSigning: FactorInstance,
		authenticationSigning: FactorInstance?
	) {
		self.transactionSigning = transactionSigning
		self.authenticationSigning = authenticationSigning
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
