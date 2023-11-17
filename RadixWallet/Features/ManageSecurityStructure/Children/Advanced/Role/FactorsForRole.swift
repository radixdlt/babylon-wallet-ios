import ComposableArchitecture
import SwiftUI
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

		return false
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
		public var destination: Destination_.State?

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

	public enum DelegateAction: Sendable, Equatable {
		case confirmedRoleWithFactors(RoleOfTier<R, FactorSource>)
	}

	public struct Destination_: DestinationReducer {
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

		public var body: some ReducerOf<Self> {
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

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.destination) {
				Destination_()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
						// FIXME: future strings
						title: { TextState("Less safe") },
						actions: {
							ButtonState(role: .destructive, action: .makeRoleLessSafe(with: roleWithFactors)) {
								// FIXME: future strings
								TextState("Decrease security")
							}
							ButtonState(role: .none, action: .discardChanges) {
								TextState(L10n.AccountSettings.ThirdPartyDeposits.discardChanges)
							}
							ButtonState(role: .cancel, action: .cancel) {
								// FIXME: future strings
								TextState(L10n.Common.cancel)
							}
						},
						message: {
							// FIXME: future strings
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

	public func reduce(into state: inout State, presentedAction: Destination_.Action) -> Effect<Action> {
		switch presentedAction {
		case let .addAdminFactor(.delegate(.selected(adminFactorSource))):
			state.adminFactorSources.append(adminFactorSource)
			state.destination = nil
			return .none

		case let .addThresholdFactor(.delegate(.selected(thresholdFactorSource))):
			state.thresholdFactorSources.append(thresholdFactorSource)
			state.destination = nil
			return .none

		case let .existingRoleMadeLessSafeConfirmationDialog(confirmationAction):
			state.destination = nil
			switch confirmationAction {
			case .cancel:
				return .none

			case .discardChanges:
				return .run { _ in
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
