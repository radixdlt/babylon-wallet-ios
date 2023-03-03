import FeaturePrelude
import GatewaysClient
import P2PConnectivityClient
import RadixConnect
import ROLAClient

// MARK: - DappInteractionHook
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RTCIncommingWalletInteraction> = []

		@PresentationState
		var currentModal: Destinations.State?
		var currentModalIsActuallyPresented = false
		@PresentationState
		var responseFailureAlert: AlertState<ViewAction.ResponseFailureAlertAction>?
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case moveToBackground
		case moveToForeground
		case responseFailureAlert(PresentationAction<AlertState<ViewAction.ResponseFailureAlertAction>, ViewAction.ResponseFailureAlertAction>)

		enum ResponseFailureAlertAction: Sendable, Hashable {
			case cancelButtonTapped(P2P.RTCIncommingWalletInteraction)
			case retryButtonTapped(P2P.RTCOutgoingMessage, for: P2P.RTCIncommingWalletInteraction, DappMetadata?)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RTCIncommingWalletInteraction)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.ToDapp.WalletInteractionResponse, for: P2P.RTCIncommingWalletInteraction, DappMetadata?)
		case failedToSendResponseToDapp(P2P.RTCOutgoingMessage, for: P2P.RTCIncommingWalletInteraction, DappMetadata?, reason: String)
		case presentResponseFailureAlert(P2P.RTCOutgoingMessage, for: P2P.RTCIncommingWalletInteraction, DappMetadata?, reason: String)
		case presentResponseSuccessView(DappMetadata)
		case ensureCurrentModalIsActuallyPresented
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationActionOf<Destinations>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<P2P.RTCIncommingWalletInteraction, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<P2P.RTCIncommingWalletInteraction, DappInteractionCoordinator.Action>)
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

	var onPresent: (@Sendable () -> Void)? = nil
	var onDismiss: (@Sendable () -> Void)? = nil

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.rolaClient) var rolaClient

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
				await p2pConnectivityClient.loadFromProfileAndConnectAll()
				let currentNetworkID = await gatewaysClient.getCurrentNetworkID()

				for try await message in await p2pConnectivityClient.receiveMessages() {
					guard !Task.isCancelled else {
						return
					}

					do {
						let interactionMessage = try message.unwrapResult()
						let interaction = interactionMessage.content.content
						guard interaction.metadata.networkId == currentNetworkID else {
							let interaction = interaction
							let incomingRequestNetwork = try Network.lookupBy(id: interaction.metadata.networkId)
							let currentNetwork = try Network.lookupBy(id: currentNetworkID)
							let outMessage = interactionMessage.toOutgoingMessage(.failure(.init(
								interactionId: interaction.id,
								errorType: .wrongNetwork,
								message: L10n.DApp.Request.wrongNetworkError(incomingRequestNetwork.name, currentNetwork.name)
							)))

							try await p2pConnectivityClient.sendMessage(outMessage)
							return
						}

						try await rolaClient.performDappDefinitionVerification(interaction.metadata)
						try await rolaClient.performWellKnownFileCheck(interaction.metadata)
						await send(.internal(.receivedRequestFromDapp(interactionMessage)))
					} catch {
						loggerGlobal.error("Failed to create Peer Connection")
						errorQueue.schedule(error)
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
		case .moveToBackground:
			return .fireAndForget {
				await p2pConnectivityClient.disconnectAndRemoveAll()
			}
		case .moveToForeground:
			return .fireAndForget {
				await p2pConnectivityClient.loadFromProfileAndConnectAll()
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .receivedRequestFromDapp(request):
			onPresent?()
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
		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return delayedPresentationEffect(for: .internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

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
		guard let next = state.requestQueue.first else {
			return .none
		}

		switch state.currentModal {
		case .some(.dappInteractionCompletion):
			return .send(.child(.modal(.presented(.dappInteractionCompletion(.delegate(.dismiss))))))
		case .none:
			state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: next.content.content)))
			return ensureCurrentModalIsActuallyPresentedEffect(for: &state)
		default:
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
				try await clock.sleep(for: .seconds(1.5))
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
			let response = request.toOutgoingMessage(responseToDapp)
			return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)

		case .modal(.presented(.dappInteractionCompletion(.delegate(.dismiss)))):
			state.currentModal = nil
			return delayedPresentationEffect(for: .internal(.presentQueuedRequestIfNeeded))
		case
			.modal(.presented(.dappInteraction(.relay(_, .delegate(.presented))))),
			.modal(.presented(.dappInteractionCompletion(.delegate(.presented)))):
			state.currentModalIsActuallyPresented = true
			return .none

		default:
			return .none
		}
	}

	func sendResponseToDappEffect(
		_ response: P2P.RTCOutgoingMessage,
		for request: P2P.RTCIncommingWalletInteraction,
		dappMetadata: DappMetadata?
	) -> EffectTask<Action> {
		.run { send in
			_ = try await p2pConnectivityClient.sendMessage(response)
			await send(.internal(.sentResponseToDapp(response.content.content, for: request, dappMetadata)))
		} catch: { error, send in
			await send(.internal(.failedToSendResponseToDapp(response, for: request, dappMetadata, reason: error.localizedDescription)))
		}
	}

	func dismissCurrentModalAndRequest(_ request: P2P.RTCIncommingWalletInteraction, for state: inout State) {
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
