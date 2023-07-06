import FeaturePrelude

// MARK: - FactorInstancesFromFactorSourcesCoordinator
/// Maps from `AbstractSecurityStructureConfiguration<FactorSource> -> AbstractSecurityStructureConfiguration<FactorInstance>`
public struct FactorInstancesFromFactorSourcesCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let structure: AbstractSecurityStructureConfiguration<FactorSource>
		public init(structure: AbstractSecurityStructureConfiguration<FactorSource>) {
			self.structure = structure
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, `continue`
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<AbstractSecurityStructureConfiguration<FactorInstance>>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .continue:
			return .send(.delegate(.done(.success(
				instantiate(factorSourceLevel: state.structure)
			))))
		}
	}
}

/// JUST A DRAFT, PSEUDOCODE, need to translate this into this TCA reducer... which will  be a BEHEMOTH of a reducer.
/// We need to handle EVERY single factor source kind, and handle FactorInstance.Badge `.virtual` AND
/// `.physical` (for the first time). `DerivePublicKeys` reducer can be used for `virtual` but `physical`
/// needs special treatment - requires a transaction - which probably should happen part of a SINGLE transaction to
/// securify the entity, rather than two TX. but for sake of simplicity in this POC we will break it up in two steps.
func instantiate(
	factorSourceLevel: AbstractSecurityStructureConfiguration<FactorSource>
) -> AbstractSecurityStructureConfiguration<FactorInstance> {
	func instancesFor<R>(
		role: RoleOfTier<R, FactorSource>
	) -> RoleOfTier<R, FactorInstance> {
		fatalError()
	}

	func instances<R>(
		for keyPath: KeyPath<AbstractSecurityStructureConfiguration<FactorSource>.Configuration, RoleOfTier<R, FactorSource>>
	) -> RoleOfTier<R, FactorInstance> {
		instancesFor(role: factorSourceLevel.configuration[keyPath: keyPath])
	}

	return .init(
		metadata: factorSourceLevel.metadata,
		configuration: .init(
			numberOfMinutesUntilAutoConfirmation: factorSourceLevel.configuration.numberOfMinutesUntilAutoConfirmation,
			primaryRole: instances(for: \.primaryRole),
			recoveryRole: instances(for: \.recoveryRole),
			confirmationRole: instances(for: \.confirmationRole)
		)
	)
}
