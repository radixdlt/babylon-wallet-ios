import FeaturePrelude

// MARK: - Permission
struct Permission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let permissionKind: PermissionKind
		let dappMetadata: DappMetadata

		enum PermissionKind: Sendable, Hashable {
			case accounts(DappInteraction.NumberOfAccounts)
			case personalData
		}

		init(
			permissionKind: PermissionKind,
			dappMetadata: DappMetadata
		) {
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case continueButtonTapped
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .continueButtonTapped:
			return .send(.delegate(.continueButtonTapped))
		}
	}
}

#if DEBUG
extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .accounts(.atLeast(2)),
		dappMetadata: .previewValue
	)
}
#endif
