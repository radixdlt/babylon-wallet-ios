import EngineToolkitimport EngineToolkit

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
	public let entityIndex: HD.Path.Component.Child.Value

	/// The factor instance which was used to create this unsecured entity, which
	/// also controls this entity and is used for signign transactions.
	public let transactionSigning: HierarchicalDeterministicFactorInstance

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: HierarchicalDeterministicFactorInstance?

	public init(
		entityIndex: HD.Path.Component.Child.Value,
		transactionSigning: HierarchicalDeterministicFactorInstance,
		authenticationSigning: HierarchicalDeterministicFactorInstance? = nil
	) {
		switch transactionSigning.derivationPath.scheme {
		case .cap26:
			if let anyAccountPath = try? transactionSigning.derivationPath.asAccountPath() {
				if let babylonAccountPath = try? anyAccountPath.asBabylonAccountPath() {
					precondition(babylonAccountPath.index == entityIndex)
				} // if BIP44 like (legacy) the `entityIndex` will not be the same as derivation path's index
			} else if let personaPath = try? transactionSigning.derivationPath.asIdentityPath() {
				precondition(personaPath.index == entityIndex)
			}
		case .bip44Olympia: break
		}
		self.entityIndex = entityIndex
		self.transactionSigning = transactionSigning
		self.authenticationSigning = authenticationSigning
	}
}

extension UnsecuredEntityControl {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			entityIndex: container.decode(HD.Path.Component.Child.Value.self, forKey: .entityIndex),
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
		try container.encode(entityIndex, forKey: .entityIndex)
		try container.encode(transactionSigning, forKey: .transactionSigning)
		try container.encodeIfPresent(authenticationSigning, forKey: .authenticationSigning)
	}

	private enum CodingKeys: String, CodingKey {
		case entityIndex
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
