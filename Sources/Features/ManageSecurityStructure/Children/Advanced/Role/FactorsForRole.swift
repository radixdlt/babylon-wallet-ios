import FeaturePrelude

extension Collection<FactorSource> {
	func filter(
		supportedByRole role: SecurityStructureRole
	) -> IdentifiedArrayOf<FactorSource> {
		.init(uncheckedUniqueElements: filter {
			$0.kind.supports(role: role)
		})
	}
}

// MARK: - RoleWithFactors
public struct RoleWithFactors: Sendable, Hashable {
	public let role: SecurityStructureRole
	public let factors: RoleOfTier<FactorSource>

	public init(
		role: SecurityStructureRole,
		factors: RoleOfTier<FactorSource>
	) {
		self.role = role
		self.factors = factors
	}
}

// MARK: - FactorsForRole
public struct FactorsForRole: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var role: SecurityStructureRole
		public var threshold: UInt?
		public var thresholdFactorSources: IdentifiedArrayOf<FactorSource>
		public var adminFactorSources: IdentifiedArrayOf<FactorSource>

		@PresentationState
		public var destination: Destinations.State?

		public init(
			role: SecurityStructureRole,
			factors: RoleOfTier<FactorSource>?
		) {
			self.role = role
			if let factors {
				self.threshold = factors.threshold
				self.thresholdFactorSources = .init(uncheckedUniqueElements: factors.thresholdFactors)
				self.adminFactorSources = .init(uncheckedUniqueElements: factors.superAdminFactors)
			} else {
				self.threshold = 0
				self.thresholdFactorSources = []
				self.adminFactorSources = []
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case addAdminFactor
		case removeAdminFactor(FactorSourceID)
		case addThresholdFactor
		case removeThresholdFactor(FactorSourceID)

		case thresholdChanged(String)
		case confirmedRoleWithFactors(RoleWithFactors)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmedRoleWithFactors(RoleWithFactors)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addThresholdFactor(SelectFactorKindThenFactor.State)
			case addAdminFactor(SelectFactorKindThenFactor.State)
		}

		public enum Action: Sendable, Equatable {
			case addThresholdFactor(SelectFactorKindThenFactor.Action)
			case addAdminFactor(SelectFactorKindThenFactor.Action)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addThresholdFactor, action: /Action.addThresholdFactor) {
				SelectFactorKindThenFactor()
			}
			Scope(state: /State.addAdminFactor, action: /Action.addAdminFactor) {
				SelectFactorKindThenFactor()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .thresholdChanged(thresholdString):
			guard let threshold = UInt(thresholdString) else {
				return .none
			}
			state.threshold = threshold
			return .none

		case .addThresholdFactor:
			state.destination = .addThresholdFactor(.init())
			return .none

		case let .removeAdminFactor(factorSourceID):
			state.adminFactorSources[id: factorSourceID] = nil
			return .none

		case let .removeThresholdFactor(factorSourceID):
			state.thresholdFactorSources[id: factorSourceID] = nil
			return .none

		case .addAdminFactor:
			state.destination = .addAdminFactor(.init())
			return .none

		case let .confirmedRoleWithFactors(roleWithFactors):
			return .send(.delegate(.confirmedRoleWithFactors(roleWithFactors)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addAdminFactor(.delegate(.selected(adminFactorSource))))):
			state.adminFactorSources.append(adminFactorSource)
			state.destination = nil
			return .none

		case let .destination(.presented(.addThresholdFactor(.delegate(.selected(thresholdFactorSource))))):
			state.thresholdFactorSources.append(thresholdFactorSource)
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
