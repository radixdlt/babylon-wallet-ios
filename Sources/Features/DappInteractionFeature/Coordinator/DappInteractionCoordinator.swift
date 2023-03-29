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
		case malformedInteractionErrorAlert(PresentationAction<MalformedInteractionErrorAlertAction>)

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
		case submit(P2P.ToDapp.WalletInteractionResponse, DappMetadata? = nil)
		case dismiss(DappMetadata? = nil)
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
			.ifLet(\.$errorAlert, action: /Action.view .. ViewAction.malformedInteractionErrorAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .malformedInteractionErrorAlert(.presented(action)):
			switch action {
			case .okButtonTapped:
				return .send(.delegate(.submit(.failure(.init(
					interactionId: state.interaction.id,
					errorType: .rejectedByUser,
					message: nil
				)))))
			}
		case .malformedInteractionErrorAlert:
			return .none
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
			return .send(.delegate(.submit(.failure(.init(
				interactionId: state.interaction.id,
				errorType: .rejectedByUser,
				message: nil
			)))))
		case let .flow(.delegate(.dismissWithFailure(error))):
			return .send(.delegate(.submit(.failure(error))))
                                // .concatenate(with: .send(.delegate(.dismiss())))

		case let .flow(.delegate(.dismissWithSuccess(dappMetadata))):
			return .send(.delegate(.dismiss(dappMetadata)))

		case let .flow(.delegate(.submit(response, dappMetadata))):
			return .send(.delegate(.submit(.success(response))))
		default:
			return .none
		}
	}
}
