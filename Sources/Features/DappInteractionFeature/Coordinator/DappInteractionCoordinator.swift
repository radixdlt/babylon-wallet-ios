import FeaturePrelude

struct DappInteractionCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum ChildState: Sendable, Hashable {
			case loading(DappInteractionLoading.State)
			case flow(DappInteractionFlow.State)
		}

		let interaction: P2P.FromDapp.WalletInteraction
		var childState: ChildState

		@PresentationState
		var errorAlert: AlertState<ViewAction.MalformedInteractionErrorAlertAction>? = nil

		init(interaction: P2P.FromDapp.WalletInteraction) {
			self.interaction = interaction
			self.childState = .loading(.init(interaction: interaction))
		}
	}

	enum ViewAction: Sendable, Equatable {
		case malformedInteractionErrorAlert(
			PresentationAction<AlertState<MalformedInteractionErrorAlertAction>,
				MalformedInteractionErrorAlertAction>
		)

		enum MalformedInteractionErrorAlertAction: Sendable, Equatable {
			case okButtonTapped
		}
	}

	enum InternalAction: Sendable, Equatable {
		case presentMalformedInteractionErrorAlert
	}

	enum ChildAction: Sendable, Equatable {
		case loading(DappInteractionLoading.Action)
		case flow(DappInteractionFlow.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissAndSubmit(P2P.ToDapp.WalletInteractionResponse)
	}

	var body: some ReducerProtocolOf<Self> {
		Scope(state: \.childState, action: /.self) {
			Scope(
				state: /State.ChildState.loading,
				action: /Action.child .. ChildAction.loading
			) {
				DappInteractionLoading()
			}
			Scope(
				state: /State.ChildState.flow,
				action: /Action.child .. ChildAction.flow
			) {
				DappInteractionFlow()
			}
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .malformedInteractionErrorAlert(action):
			state.errorAlert = nil
			switch action {
			case .dismiss, .present:
				return .none
			case .presented(.okButtonTapped):
				return .send(.delegate(.dismissAndSubmit(.failure(.init(
					interactionId: state.interaction.id,
					errorType: .rejectedByUser,
					message: nil
				)))))
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .loading(.delegate(.dappMetadataLoaded(dappMetadata))):
			if let flowState = DappInteractionFlow.State(dappMetadata: dappMetadata, interaction: state.interaction) {
				state.childState = .flow(flowState)
			} else {
				state.errorAlert = .init(
					title: { TextState(L10n.App.errorOccurredTitle) },
					actions: {
						ButtonState(role: .cancel, action: .send(.okButtonTapped)) {
							TextState(L10n.DApp.Request.MalformedErrorAlert.okButtonTitle)
						}
					},
					message: { TextState(L10n.DApp.Request.MalformedErrorAlert.message) }
				)
			}
			return .none
		case .loading(.delegate(.dismiss)):
			return .send(.delegate(.dismissAndSubmit(.failure(.init(
				interactionId: state.interaction.id,
				errorType: .rejectedByUser,
				message: nil
			)))))
		case let .flow(.delegate(.dismiss(error))):
			return .send(.delegate(.dismissAndSubmit(.failure(error))))
		case let .flow(.delegate(.submit(response))):
			return .send(.delegate(.dismissAndSubmit(.success(response))))
		default:
			return .none
		}
	}
}
