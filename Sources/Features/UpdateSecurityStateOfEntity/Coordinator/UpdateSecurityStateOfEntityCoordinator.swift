import FeaturePrelude
import SecurityStructureConfigurationListFeature
import TransactionReviewFeature

// MARK: - UpdateSecurityStateOfEntityCoordinator
public struct UpdateSecurityStateOfEntityCoordinator<Entity: EntityProtocol & Sendable & Hashable>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: Entity

		public var root: Path.State
		public var path: StackState<Path.State> = .init()

		public init(entity: Entity) {
			self.entity = entity
			self.root = .selectSecurityStructureConfig(.init(
				configList: .init(context: .securifyEntity)
			))
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectSecurityStructureConfig(SecurityStructureConfigurationListCoordinator.State)
			case securifyEntity(TransactionReview.State)
		}

		public enum Action: Sendable, Equatable {
			case selectSecurityStructureConfig(SecurityStructureConfigurationListCoordinator.Action)
			case securifyEntity(TransactionReview.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.selectSecurityStructureConfig, action: /Action.selectSecurityStructureConfig) {
				SecurityStructureConfigurationListCoordinator()
			}
			Scope(state: /State.securifyEntity, action: /Action.securifyEntity) {
				TransactionReview()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .root(.selectSecurityStructureConfig(.delegate(.selectedConfig(configDetailed)))):
			let manifest = manifest(for: configDetailed, entity: state.entity)
			state.path.append(.securifyEntity(.init(
				transactionManifest: manifest,
				nonce: Nonce.secureRandom(),
				signTransactionPurpose: .internalManifest(.securifyEntity(kind: Entity.entityKind)),
				message: nil
			)))
			return .none

		default:
			return .none
		}
	}
}

extension UpdateSecurityStateOfEntityCoordinator.State where Entity == Profile.Network.Account {
	public init(account: Entity) {
		self.init(entity: account)
	}
}

extension UpdateSecurityStateOfEntityCoordinator.State where Entity == Profile.Network.Persona {
	public init(persona: Entity) {
		self.init(entity: persona)
	}
}

private func manifest(
	for configDetailed: SecurityStructureConfigurationDetailed,
	entity: some EntityProtocol
) -> TransactionManifest {
	guard case .unsecured = entity.securityState else {
		fatalError()
	}

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
			instancesFor(role: configDetailed.configuration[keyPath: keyPath])
		}
		return .init(
			metadata: configDetailed.metadata,
			configuration: .init(
				numberOfMinutesUntilAutoConfirmation: configDetailed.configuration.numberOfMinutesUntilAutoConfirmation,
				primaryRole: instances(for: \.primaryRole),
				recoveryRole: instances(for: \.recoveryRole),
				confirmationRole: instances(for: \.confirmationRole)
			)
		)
	}

	let securityStructure = instantiate(factorSourceLevel: configDetailed)

	let ruleSet: Tuple = {
		func rulesFor<R>(role: RoleOfTier<R, FactorInstance>) -> ManifestASTValue {
			.string("Placeholder")
		}
		func rules<R>(
			for keypath: KeyPath<AbstractSecurityStructureConfiguration<FactorInstance>.Configuration, RoleOfTier<R, FactorInstance>>
		) -> ManifestASTValue {
			rulesFor(role: securityStructure.configuration[keyPath: keypath])
		}
		return Tuple(values: [
			rules(for: \.primaryRole),
			rules(for: \.recoveryRole),
			rules(for: \.confirmationRole),
		])
	}()

	return TransactionManifest {
		CreateAccessController(
			controlledAsset: Bucket(value: entity.address.address),
			ruleSet: ruleSet,
			timedRecoveryDelayInMinutes: .u64(securityStructure.configuration.numberOfMinutesUntilAutoConfirmation.rawValue)
		)
	}
}
