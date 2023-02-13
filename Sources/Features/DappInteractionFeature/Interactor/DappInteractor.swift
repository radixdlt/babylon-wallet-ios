import FeaturePrelude
import P2PConnectivityClient
import ProfileClient

// MARK: - DappInteractionHook
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RequestFromClient> = []

		@PresentationState
		var currentModal: Destinations.State?
		var currentModalIsActuallyPresented = false
		@PresentationState
		var responseFailureAlert: AlertState<ViewAction.ResponseFailureAlertAction>?
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case responseFailureAlert(PresentationAction<AlertState<ViewAction.ResponseFailureAlertAction>, ViewAction.ResponseFailureAlertAction>)

		enum ResponseFailureAlertAction: Sendable, Hashable {
			case cancelButtonTapped(P2P.RequestFromClient)
			case retryButtonTapped(P2P.ResponseToClientByID, for: P2P.RequestFromClient, DappMetadata?)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RequestFromClient)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.ToDapp.WalletInteractionResponse, for: P2P.RequestFromClient, DappMetadata?)
		case presentResponseFailureAlert(P2P.ResponseToClientByID, for: P2P.RequestFromClient, DappMetadata?, reason: String)
		case presentResponseSuccessView(DappMetadata)
		case ensureCurrentModalIsActuallyPresented
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationActionOf<Destinations>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<P2P.RequestFromClient, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<P2P.RequestFromClient, DappInteractionCoordinator.Action>)
			case dappInteractionCompletion(Completion.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.dappInteraction, action: /Action.dappInteraction) {
				Relay { DappInteractionCoordinator() }
			}
			Scope(state: /State.dappInteractionCompletion, action: /Action.dappInteractionCompletion) {
				Completion()
			}
		}
	}

	let onDismiss: (@Sendable () -> Void)?

	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$currentModal, action: /Action.child .. ChildAction.modal) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				try await p2pConnectivityClient.loadFromProfileAndConnectAll()
				for try await clientIDs in try await p2pConnectivityClient.getP2PClientIDs() {
					guard !Task.isCancelled else {
						return
					}
					for clientID in clientIDs {
						for try await request in try await p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence(clientID) {
							try await p2pConnectivityClient.sendMessageReadReceipt(clientID, request.originalMessage)

							let currentNetworkID = await profileClient.getCurrentNetworkID()

							guard request.interaction.metadata.networkId == currentNetworkID else {
								let incomingRequestNetwork = try Network.lookupBy(id: request.interaction.metadata.networkId)
								let currentNetwork = try Network.lookupBy(id: currentNetworkID)

								_ = try await p2pConnectivityClient.sendMessage(.init(
									connectionID: request.client.id,
									responseToDapp: .failure(
										.init(
											interactionId: request.interaction.id,
											errorType: .wrongNetwork,
											message: L10n.DApp.Request.wrongNetworkError(incomingRequestNetwork.name, currentNetwork.name)
										)
									)
								))
								continue
							}

							await send(.internal(.receivedRequestFromDapp(request)))
						}
					}
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .responseFailureAlert(action):
			state.responseFailureAlert = nil
			switch action {
			case .dismiss, .present:
				return .none
			case let .presented(.cancelButtonTapped(request)):
				dismissCurrentModalAndRequest(request, for: &state)
				return delayedPresentationEffect(for: .internal(.presentQueuedRequestIfNeeded))
			case let .presented(.retryButtonTapped(response, request, dappMetadata)):
				return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .receivedRequestFromDapp(request):
			state.requestQueue.append(request)
			return presentQueuedRequestIfNeededEffect(for: &state)

		case .presentQueuedRequestIfNeeded:
			return presentQueuedRequestIfNeededEffect(for: &state)

		case let .sentResponseToDapp(response, for: request, dappMetadata):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return delayedPresentationEffect(
					for: .internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil)))
				)
			case .failure:
				return delayedPresentationEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

		case let .presentResponseFailureAlert(response, for: request, dappMetadata, reason):
			state.responseFailureAlert = .init(
				title: { TextState(L10n.App.errorOccurredTitle) },
				actions: {
					ButtonState(role: .cancel, action: .cancelButtonTapped(request)) {
						TextState(L10n.DApp.Response.FailureAlert.cancelButtonTitle)
					}
					ButtonState(action: .retryButtonTapped(response, for: request, dappMetadata)) {
						TextState(L10n.DApp.Response.FailureAlert.retryButtonTitle)
					}
				},
				message: { TextState(L10n.DApp.Response.FailureAlert.message(reason)) }
			)
			return .none

		case let .presentResponseSuccessView(dappMetadata):
			state.currentModal = .dappInteractionCompletion(.init(dappMetadata: dappMetadata))
			return ensureCurrentModalIsActuallyPresentedEffect(for: &state)

		case .ensureCurrentModalIsActuallyPresented:
			return ensureCurrentModalIsActuallyPresentedEffect(for: &state)
		}
	}

	func presentQueuedRequestIfNeededEffect(
		for state: inout State
	) -> EffectTask<Action> {
		if
			state.currentModal == nil,
			let next = state.requestQueue.first
		{
			state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: next.interaction)))
			return ensureCurrentModalIsActuallyPresentedEffect(for: &state)
		} else {
			return .none
		}
	}

	func ensureCurrentModalIsActuallyPresentedEffect(
		for state: inout State
	) -> EffectTask<Action> {
		guard let currentModal = state.currentModal else { return .none }
		if state.currentModalIsActuallyPresented == false {
			state.currentModal = nil
			state.currentModal = currentModal
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.ensureCurrentModalIsActuallyPresented))
			}
		} else {
			state.currentModalIsActuallyPresented = false
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submitAndDismiss(responseToDapp, dappMetadata)))))):
			let response = P2P.ResponseToClientByID(
				connectionID: request.client.id,
				responseToDapp: responseToDapp
			)
			return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)

		case .modal(.presented(.dappInteractionCompletion(.delegate(.dismiss)))):
			state.currentModal = nil
			return delayedPresentationEffect(for: .internal(.presentQueuedRequestIfNeeded))

		case
			.modal(.presented(.dappInteraction(.relay(_, .delegate(.presented))))),
			.modal(.presented(.dappInteractionCompletion(.delegate(.presented)))):
			state.currentModalIsActuallyPresented = true
			return .none

		// NB: handles "background tap to dismiss" for success screen.
		case .modal(.dismiss):
			switch state.currentModal {
			case .none, .dappInteraction:
				return .none
			case .dappInteractionCompletion:
				return delayedPresentationEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

		default:
			return .none
		}
	}

	func sendResponseToDappEffect(
		_ response: P2P.ResponseToClientByID,
		for request: P2P.RequestFromClient,
		dappMetadata: DappMetadata?
	) -> EffectTask<Action> {
		.run { send in
			_ = try await p2pConnectivityClient.sendMessage(response)
			await send(.internal(.sentResponseToDapp(response.responseToDapp, for: request, dappMetadata)))
		} catch: { error, send in
			await send(.internal(.presentResponseFailureAlert(response, for: request, dappMetadata, reason: error.legibleLocalizedDescription)))
		}
	}

	func dismissCurrentModalAndRequest(_ request: P2P.RequestFromClient, for state: inout State) {
		state.requestQueue.remove(request)
		state.currentModal = nil
		onDismiss?()
	}

	func delayedPresentationEffect(
		delay: Duration = .seconds(0.75),
		for action: Action
	) -> EffectTask<Action> {
		.run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}
