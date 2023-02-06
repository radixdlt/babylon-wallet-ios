import FeaturePrelude

// MARK: - Permission
struct Permission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let interactionItem: DappInteractionFlow.State.AnyInteractionItem! // TODO: @davdroman factor out onto Proxy reducer
		let permissionKind: PermissionKind
		let dappMetadata: DappMetadata

		enum PermissionKind: Sendable, Hashable {
			case accounts(DappInteraction.NumberOfAccounts)
			case personalData
		}

		init(
			interactionItem: DappInteractionFlow.State.AnyInteractionItem!,
			permissionKind: PermissionKind,
			dappMetadata: DappMetadata
		) {
			self.interactionItem = interactionItem
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped(DappInteractionFlow.State.AnyInteractionItem)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .continueButtonTapped:
			return .send(.delegate(.continueButtonTapped(state.interactionItem)))
		}
	}
}

#if DEBUG
extension Permission.State {
	static let previewValue: Self = .init(
		interactionItem: nil,
		permissionKind: .accounts(.atLeast(2)),
		dappMetadata: .previewValue
	)
}
#endif
