import ComposableArchitecture
import SwiftUI

struct DappInteractionCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum ChildState: Sendable, Hashable {
			case loading(DappInteractionLoading.State)
			case originVerification(DappInteractionOriginVerification.State)
			case flow(DappInteractionFlow.State)
		}

		let request: RequestEnvelope
		var childState: ChildState

		@PresentationState
		var errorAlert: AlertState<ViewAction.MalformedInteractionErrorAlertAction>? = nil

		init(request: RequestEnvelope) {
			self.request = request
			self.childState = .loading(.init(interaction: request.interaction))
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
		case originVerification(DappInteractionOriginVerification.Action)
		case flow(DappInteractionFlow.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case submit(WalletToDappInteractionResponse, DappMetadata)
		case dismiss(DappMetadata, DappInteractionCompletionKind)
		case dismissSilently
		case pollPreAuthorizationStatus(PreAuthorizationReview.PollingStatus.Config)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.childState, action: /.self) {
			Scope(state: /State.ChildState.loading, action: /Action.child .. ChildAction.loading) {
				DappInteractionLoading()
			}
			Scope(state: /State.ChildState.originVerification, action: /Action.child .. ChildAction.originVerification) {
				DappInteractionOriginVerification()
			}
			Scope(state: /State.ChildState.flow, action: /Action.child .. ChildAction.flow) {
				DappInteractionFlow()
			}
		}
		Reduce(core)
			.ifLet(\.$errorAlert, action: /Action.view .. ViewAction.malformedInteractionErrorAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .malformedInteractionErrorAlert(.presented(action)):
			switch action {
			case .okButtonTapped:
				sendRequestRejected(state)
			}

		case .malformedInteractionErrorAlert:
			.none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .loading(.delegate(.dappMetadataLoaded(dappMetadata))):
			if state.request.requiresOriginValidation {
				state.childState = .originVerification(.init(dAppMetadata: dappMetadata))
				return .none
			}

			return startFlow(&state, dappMetadata: dappMetadata)

		case .loading(.delegate(.dismiss)):
			return sendRequestRejected(state)

		case .originVerification(.delegate(.cancel)):
			return sendRequestRejected(state)

		case let .originVerification(.delegate(.continueFlow(dappMetadata))):
			return startFlow(&state, dappMetadata: dappMetadata)

		case let .flow(.delegate(.dismissWithFailure(error))):
			return .send(.delegate(.submit(.failure(error), .request(state.request.interaction.metadata))))

		case let .flow(.delegate(.dismissWithSuccess(dappMetadata, kind))):
			return .send(.delegate(.dismiss(dappMetadata, kind)))

		case .flow(.delegate(.dismiss)):
			return .send(.delegate(.dismissSilently))

		case let .flow(.delegate(.submit(response, dappMetadata))):
			return .send(.delegate(.submit(.success(response), dappMetadata)))

		case let .flow(.delegate(.pollPreAuthorizationStatus(config))):
			return .send(.delegate(.pollPreAuthorizationStatus(config)))

		default:
			return .none
		}
	}

	private func startFlow(_ state: inout State, dappMetadata: DappMetadata) -> Effect<Action> {
		if let flowState = DappInteractionFlow.State(
			dappMetadata: dappMetadata,
			interaction: state.request.interaction,
			p2pRoute: state.request.route
		) {
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
	}

	private func sendRequestRejected(_ state: State) -> Effect<Action> {
		.send(.delegate(.submit(
			.failure(
				.init(
					interactionId: state.request.interaction.interactionId,
					error: .rejectedByUser,
					message: nil
				)
			),
			.request(state.request.interaction.metadata)
		)))
	}
}
