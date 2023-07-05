import Cryptography
import Prelude

// MARK: - Securified
public struct Securified: Sendable, Hashable, Codable {
	public let entityIndex: HD.Path.Component.Child.Value

	public let accessController: AccessController

	/// Single place for factor instances for this securified entity.
	private var transactionSigningFactorInstances: NonEmpty<OrderedSet<FactorInstance>>

	/// The factor instance which can be used for ROLA.
	public var authenticationSigning: HierarchicalDeterministicFactorInstance // REQUIRED because if not set, we do not know which transactionSigningFactorInstance to default to... there is no singular. MUTABLE since if user changes phone, we must update it to device factor source of new phone.

	/// The factor instance used to encrypt/decrypt messages.
	public let messageEncryption: HierarchicalDeterministicFactorInstance // could be optional actually, but why not set it during securification (if not set)

	public init(
		entityIndex: HD.Path.Component.Child.Value,
		transactionSigningFactorInstances: NonEmpty<OrderedSet<FactorInstance>>,
		accessController: AccessController,
		authenticationSigning: HierarchicalDeterministicFactorInstance,
		messageEncryption: HierarchicalDeterministicFactorInstance
	) {
		self.entityIndex = entityIndex
		self.transactionSigningFactorInstances = transactionSigningFactorInstances
		self.accessController = accessController
		self.authenticationSigning = authenticationSigning
		self.messageEncryption = messageEncryption
	}

	/// Maps from `FactorInstance.ID` to `FactorInstance`, which is what is useful for use through out the wallet.
	public var transactionSigningStructure: AbstractSecurityStructure<FactorInstance> {
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
