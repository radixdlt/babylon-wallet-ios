import FeaturePrelude

struct DappInteractionCoordinator: Sendable, FeatureReducer {
	enum State: Sendable, Hashable {
		case loading(DappInteractionLoading.State)
		case flow(DappInteractionFlow.State)
//		case submitting(DappInteractionSubmitting.State)

		var interaction: P2P.FromDapp.WalletInteraction {
			switch self {
			case let .loading(state):
				return state.interaction
			case let .flow(state):
				return state.interaction
			}
		}
	}

	enum ChildAction: Sendable, Equatable {
		case loading(DappInteractionLoading.Action)
		case flow(DappInteractionFlow.Action)
//		case submitting(DappInteractionSubmitting.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .loading(.delegate(.dappMetadataLoaded(dappMetadata))):
			withAnimation(.easeInOut) {
				state = .flow(.init(dappMetadata: dappMetadata, interaction: state.interaction))
			}
			return .none
		case .loading(.delegate(.dismiss)):
			return .run { send in await send(.delegate(.dismiss)) }
		default:
			return .none
		}
	}
}
