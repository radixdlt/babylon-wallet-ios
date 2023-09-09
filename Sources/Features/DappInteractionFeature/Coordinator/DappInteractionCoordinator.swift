import EngineKit
import FeaturePrelude

struct DappInteractionCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum ChildState: Sendable, Hashable {
			case loading(DappInteractionLoading.State)
			case flow(DappInteractionFlow.State)
		}

		let interaction: P2P.Dapp.Request
		var childState: ChildState

		@PresentationState
		var errorAlert: AlertState<ViewAction.MalformedInteractionErrorAlertAction>? = nil

		init(interaction: P2P.Dapp.Request) {
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
		case submit(P2P.Dapp.Response, DappMetadata)
		case dismiss(DappMetadata, TXID)
		case dismissSilently
	}

	var body: some ReducerProtocolOf<Self> {
		Scope(state: \.childState, action: /.self) {
			Scope(state: /State.ChildState.loading, action: /Action.child .. ChildAction.loading) {
				DappInteractionLoading()
			}
			Scope(state: /State.ChildState.flow, action: /Action.child .. ChildAction.flow) {
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
				)), .request(state.interaction.metadata))))
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
					title: { TextState(L10n.Common.errorAlertTitle) },
					actions: {
						ButtonState(role: .cancel, action: .send(.okButtonTapped)) {
							TextState(L10n.Common.ok)
						}
					},
					message: { TextState(L10n.DAppRequest.RequestMalformedAlert.message) }
				)
			}
			return .none

		case .loading(.delegate(.dismiss)):
			return .send(.delegate(.submit(.failure(.init(
				interactionId: state.interaction.id,
				errorType: .rejectedByUser,
				message: nil
			)), .request(state.interaction.metadata))))

		case let .flow(.delegate(.dismissWithFailure(error))):
			return .send(.delegate(.submit(.failure(error), .request(state.interaction.metadata))))

		case let .flow(.delegate(.dismissWithSuccess(dappMetadata, txID))):
			return .send(.delegate(.dismiss(dappMetadata, txID)))

		case .flow(.delegate(.dismiss)):
			return .send(.delegate(.dismissSilently))

		case let .flow(.delegate(.submit(response, dappMetadata))):
			return .send(.delegate(.submit(.success(response), dappMetadata)))

		default:
			return .none
		}
	}
}
