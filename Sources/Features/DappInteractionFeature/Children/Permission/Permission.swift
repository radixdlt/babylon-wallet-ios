import FeaturePrelude

// MARK: - Permission
struct Permission: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let permissionKind: DappInteraction.PermissionKind
		let dappMetadata: DappMetadata

		init(
			permissionKind: DappInteraction.PermissionKind,
			dappMetadata: DappMetadata
		) {
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}

#if DEBUG
extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .accounts(.ongoing),
		dappMetadata: .previewValue
	)
}
#endif
