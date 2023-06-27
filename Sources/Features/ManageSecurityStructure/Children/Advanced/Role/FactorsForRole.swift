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

// MARK: - ExistingRoleMadeLessSafeConfirmationDialog
public enum ExistingRoleMadeLessSafeConfirmationDialog<R: RoleProtocol>: Sendable, Hashable {
	case makeRoleLessSafe(with: RoleOfTier<R, FactorSource>)
	case discardChanges
	case cancel
}

extension RoleOfTier where AbstractFactor == FactorSource {
	func isLessSafe(than other: Self) -> Bool {
		if thresholdFactors.count < other.thresholdFactors.count {
			// We consider FEWER threshold factors LESS safe
			return true
		}
		if threshold < other.threshold {
			// We consider requiring FEWER threshold factors be used LESS safe.
			return true
		}

		// We consider MORE admin factors LESS safe ONLY if thresholdFactors is empty,
		// since if thresholdFactors is empty, using any admin factor is more safe than no factors at all.
		if thresholdFactors.isEmpty {
			return superAdminFactors.count < other.superAdminFactors.count
		} else {
			return superAdminFactors.count > other.superAdminFactors.count
		}
	}
}

// MARK: - FactorsForRole
public struct FactorsForRole<R: RoleProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var role: SecurityStructureRole
		public var thresholdString: String
		public var thresholdFactorSources: IdentifiedArrayOf<FactorSource>
		public var adminFactorSources: IdentifiedArrayOf<FactorSource>

		@PresentationState
		public var destination: Destinations.State?

		public let existing: RoleOfTier<R, FactorSource>?

		public init(
			role: SecurityStructureRole,
			factors exiting: RoleOfTier<R, FactorSource>?
		) {
			self.role = role
			if let exiting {
				self.thresholdString = exiting.threshold.description
				self.thresholdFactorSources = .init(uncheckedUniqueElements: exiting.thresholdFactors)
				self.adminFactorSources = .init(uncheckedUniqueElements: exiting.superAdminFactors)
				self.existing = exiting
			} else {
				self.thresholdString = "0"
				self.thresholdFactorSources = []
				self.adminFactorSources = []
				self.existing = nil
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case addAdminFactor
		case removeAdminFactor(FactorSourceID)
		case addThresholdFactor
		case removeThresholdFactor(FactorSourceID)

		case thresholdChanged(String)
		case confirmedRoleWithFactors(RoleOfTier<R, FactorSource>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmedRoleWithFactors(RoleOfTier<R, FactorSource>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addThresholdFactor(SelectFactorKindThenFactor.State)
			case addAdminFactor(SelectFactorKindThenFactor.State)

			case existingRoleMadeLessSafeConfirmationDialog(ConfirmationDialogState<ExistingRoleMadeLessSafeConfirmationDialog<R>>)
		}

		public enum Action: Sendable, Equatable {
			case addThresholdFactor(SelectFactorKindThenFactor.Action)
			case addAdminFactor(SelectFactorKindThenFactor.Action)

			case existingRoleMadeLessSafeConfirmationDialog(ExistingRoleMadeLessSafeConfirmationDialog<R>)
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

	@Dependency(\.dismiss) var dismiss
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
			state.thresholdString = thresholdString
			return .none

		case .addThresholdFactor:
			state.destination = .addThresholdFactor(.init(role: state.role))
			return .none

		case let .removeAdminFactor(factorSourceID):
			state.adminFactorSources[id: factorSourceID] = nil
			return .none

		case let .removeThresholdFactor(factorSourceID):
			state.thresholdFactorSources[id: factorSourceID] = nil
			return .none

		case .addAdminFactor:
			state.destination = .addAdminFactor(.init(role: state.role))
			return .none

		case let .confirmedRoleWithFactors(roleWithFactors):
			if let existing = state.existing, roleWithFactors.isLessSafe(than: existing) {
				state.destination = .existingRoleMadeLessSafeConfirmationDialog(
					.init(
						// FIXME: strings
						title: { TextState("Less safe") },
						actions: {
							ButtonState(role: .destructive, action: .makeRoleLessSafe(with: roleWithFactors)) {
								// FIXME: strings
								TextState("Decrease security")
							}
							ButtonState(role: .none, action: .discardChanges) {
								// FIXME: strings
								TextState("Discard changes")
							}
							ButtonState(role: .cancel, action: .cancel) {
								// FIXME: strings
								TextState("Cancel")
							}
						},
						message: {
							// FIXME: strings
							TextState("You are about to decrease the level of security you had setup by removing factors. Are you sure you want to do that?")
						}
					)
				)
				return .none
			} else {
				return .send(.delegate(.confirmedRoleWithFactors(roleWithFactors)))
			}
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

		case let .destination(.presented(.existingRoleMadeLessSafeConfirmationDialog(confirmationAction))):
			state.destination = nil
			switch confirmationAction {
			case .cancel:
				return .none

			case .discardChanges:
				return .fireAndForget {
					await dismiss()
				}

			case let .makeRoleLessSafe(with: roleWithFactors):
				return .send(.delegate(.confirmedRoleWithFactors(roleWithFactors)))
			}

		default:
			return .none
		}
	}
}
