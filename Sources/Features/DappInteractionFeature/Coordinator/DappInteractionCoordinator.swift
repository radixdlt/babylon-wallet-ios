import FeaturePrelude

struct DappInteractionCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Stage {
			case loading(DappInteractionLoading.State)
			case flow(DappInteractionFlow.State)
//			case submitting(DappInteractionSubmitting.State)
		}

		let interaction: P2P.FromDapp.WalletInteraction
		var stage: Stage
		var errorAlert: AlertState<ViewAction.MalformedInteractionErrorAlertAction>? = nil

		init(interaction: P2P.FromDapp.WalletInteraction) {
			self.interaction = interaction
			self.stage = .loading(.init(interaction: interaction))
		}
	}

	enum ViewAction: Sendable, Equatable {
		case malformedInteractionErrorAlert(MalformedInteractionErrorAlertAction)

		enum MalformedInteractionErrorAlertAction: Sendable, Equatable {
			case okButtonTapped
			case systemDismissed
		}
	}

	enum InternalAction: Sendable, Equatable {
		case presentMalformedInteractionErrorAlert
	}

	enum ChildAction: Sendable, Equatable {
		case loading(DappInteractionLoading.Action)
		case flow(DappInteractionFlow.Action)
//		case submitting(DappInteractionSubmitting.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	var body: some ReducerProtocolOf<Self> {
		Scope(state: \.stage, action: /.self) {
			Scope(
				state: /State.loading,
				action: /Action.child .. ChildAction.loading
			) {
				DappInteractionLoading()
			}
			Scope(
				state: /State.flow,
				action: /Action.child .. ChildAction.flow
			) {
				DappInteractionFlow()
			}
		}

		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .loading(.delegate(.dappMetadataLoaded(dappMetadata))):
			if let flowState = DappInteractionFlow.State(dappMetadata: dappMetadata, remoteInteraction: state.interaction) {
				state.stage = .flow(flowState)
			} else {
				state.errorAlert = .init(
					title: { TextState(L10n.App.errorOccurredTitle) },
					actions: [
						ButtonState(role: .cancel, action: .send(.okButtonTapped)) {
							TextState(L10n.DApp.Request.MalformedErrorAlert.okButtonTitle)
						},
					],
					message: { TextState(L10n.DApp.Request.MalformedErrorAlert.message) }
				)
			}
			return .none
		case .loading(.delegate(.dismiss)):
			return .send(.delegate(.dismiss))
		default:
			return .none
		}
	}
}
