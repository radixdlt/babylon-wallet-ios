import Prelude

// MARK: - Securified
public struct Securified: Sendable, Hashable, Codable {
	public let accessController: AccessController

	/// Single place for factor instances for this securified entity.
	private var transactionSigningFactorInstances: OrderedSet<FactorInstance>

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: HierarchicalDeterministicFactorInstance?
	/// The factor instance used to encrypt/decrypt messages
	public var messageEncryption: HierarchicalDeterministicFactorInstance?

	/// Maps from `FactorInstance.ID` to `FactorInstance`, which is what is useful for use through out the wallet.
	var transactionSigningStructure: AppliedSecurityStructure {
		func decorate<R: RoleProtocol>(
			_ keyPath: KeyPath<ProfileSnapshot.AppliedSecurityStructure, RoleOfTier<R, FactorInstance.ID>>
		) -> RoleOfTier<R, FactorInstance> {
			let roleWithfactorInstanceIDs = accessController.securityStructure[keyPath: keyPath]

			func lookup(id: FactorInstance.ID) -> FactorInstance {
				guard let factorInstance = transactionSigningFactorInstances.first(where: { $0.id == id }) else {
					let errorMessage = "Critical error, unable to find factor instance with ID: \(id), this should never happen."
					loggerGlobal.critical(.init(stringLiteral: errorMessage))
					fatalError(errorMessage)
				}
				return factorInstance
			}

			return .init(
				uncheckedThresholdFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.thresholdFactors.map(lookup(id:))),
				superAdminFactors: .init(uncheckedUniqueElements: roleWithfactorInstanceIDs.superAdminFactors.map(lookup(id:))),
				threshold: roleWithfactorInstanceIDs.threshold
			)
		}

		return .init(
			numberOfDaysUntilAutoConfirmation: accessController.securityStructure.numberOfDaysUntilAutoConfirmation,
			primaryRole: decorate(\.primaryRole),
			recoveryRole: decorate(\.recoveryRole),
			confirmationRole: decorate(\.confirmationRole)
		)
	}
}
