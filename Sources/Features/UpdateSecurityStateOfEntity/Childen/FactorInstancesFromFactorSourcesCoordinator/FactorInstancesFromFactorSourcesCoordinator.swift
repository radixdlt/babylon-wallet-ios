import DerivePublicKeysFeature
import FeaturePrelude

extension FactorSource {
	var producesVirtualBadges: Bool {
		fatalError()
	}
}

extension RoleOfTier where AbstractFactor == FactorSource {
	var producesVirtualBadges: Bool {
		thresholdFactors.contains(where: \.producesVirtualBadges) || superAdminFactors.contains(where: \.producesVirtualBadges)
	}
}

extension AbstractSecurityStructureConfiguration<FactorSource> {
	var producesVirtualBadges: Bool {
		let conf = configuration
		return conf.primaryRole.producesVirtualBadges || conf.recoveryRole.producesVirtualBadges || conf.confirmationRole.producesVirtualBadges
	}

	var virtualFactorBadgeSources: VirtualFactorBadgeSources {
		fatalError()
	}

	var physicalFactorBadgeSources: PhysicalFactorBadgeSources {
		fatalError()
	}
}

public typealias VirtualFactorBadgeSources = OrderedDictionary<FactorSource, OrderedSet<DerivationPath>>
public typealias PhysicalFactorBadgeSources = OrderedSet<TrustedContactFactorSource>

// MARK: - FactorInstancesFromFactorSourcesCoordinator
/// Maps from `AbstractSecurityStructureConfiguration<FactorSource> -> AbstractSecurityStructureConfiguration<FactorInstance>`
public struct FactorInstancesFromFactorSourcesCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID
		public let structure: AbstractSecurityStructureConfiguration<FactorSource>
		public var step: Step

		public enum Step: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
			case mintTrustedContactBadges
		}

		public var virtualFactorBadgeSources: VirtualFactorBadgeSources
		public var physicalFactorBadgeSources: PhysicalFactorBadgeSources

		public init(structure: AbstractSecurityStructureConfiguration<FactorSource>, networkID: NetworkID) {
			self.networkID = networkID
			self.structure = structure
			var virtualFactorBadgeSources = structure.virtualFactorBadgeSources
			var physicalFactorBadgeSources = structure.physicalFactorBadgeSources
			if let derivePublicKeysState = Self.nextVirtualBadgeSource(
				from: &virtualFactorBadgeSources,
				networkID: networkID
			) {
				self.step = .derivePublicKeys(derivePublicKeysState)
			} else if let derivePublicKeysState = Self.nextPhysicalBadgeSource(
				from: &physicalFactorBadgeSources,
				networkID: networkID
			) {
				self.step = .derivePublicKeys(derivePublicKeysState)
			} else {
				fatalError("No step?!")
			}
			self.virtualFactorBadgeSources = virtualFactorBadgeSources
			self.physicalFactorBadgeSources = physicalFactorBadgeSources
		}

		static func nextVirtualBadgeSource(
			from virtualFactorBadgeSources: inout VirtualFactorBadgeSources,
			networkID: NetworkID
		) -> DerivePublicKeys.State? {
			guard
				let factorSource = virtualFactorBadgeSources.keys.first,
				let derivationPaths = virtualFactorBadgeSources[factorSource]
			else {
				return nil
			}
			return .init(
				derivationPathOption: .knownPaths(derivationPaths, networkID: networkID),
				factorSourceOption: .specific(factorSource),
				purpose: .createAuthSigningKey
			)
		}

		static func nextPhysicalBadgeSource(
			from physicalFactorBadgeSources: inout PhysicalFactorBadgeSources,
			networkID: NetworkID
		) -> DerivePublicKeys.State? {
			fatalError()
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared, `continue`
	}

	public enum ChildAction: Sendable, Equatable {
		case derivePublicKeys(DerivePublicKeys.Action)
		case mintTrustedContactBadges
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(TaskResult<AbstractSecurityStructureConfiguration<FactorInstance>>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.derivePublicKeys,
				action: /Action.child .. ChildAction.derivePublicKeys
			) {
				DerivePublicKeys()
			}
		}

		Reduce(core)
	}

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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .derivePublicKeys(.delegate(.derivedPublicKeys(hdPublicKeys, factorSourceID, networkID))):
			state.
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
