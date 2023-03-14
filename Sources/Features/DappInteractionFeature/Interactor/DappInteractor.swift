import FeaturePrelude
import GatewaysClient
import RadixConnect
import RadixConnectClient
import ROLAClient

// MARK: - DappInteractionHook
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RTCIncomingWalletInteraction> = []

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
		case responseFailureAlert(PresentationAction<ResponseFailureAlertAction>)

		enum ResponseFailureAlertAction: Sendable, Hashable {
			case cancelButtonTapped(P2P.RTCIncomingWalletInteraction)
			case retryButtonTapped(P2P.RTCOutgoingMessage, for: P2P.RTCIncomingWalletInteraction, DappMetadata?)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RTCIncomingWalletInteraction)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.ToDapp.WalletInteractionResponse, for: P2P.RTCIncomingWalletInteraction, DappMetadata?)
		case failedToSendResponseToDapp(P2P.RTCOutgoingMessage, for: P2P.RTCIncomingWalletInteraction, DappMetadata?, reason: String)
		case presentResponseFailureAlert(P2P.RTCOutgoingMessage, for: P2P.RTCIncomingWalletInteraction, DappMetadata?, reason: String)
		case presentResponseSuccessView(DappMetadata)
		case ensureCurrentModalIsActuallyPresented
		case checkCanShowDappInteraction
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationAction<Destinations.Action>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<P2P.RTCIncomingWalletInteraction, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<P2P.RTCIncomingWalletInteraction, DappInteractionCoordinator.Action>)
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
	var canShowInteraction: @Sendable () -> Bool = { true }

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.rolaClient) var rolaClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$currentModal, action: /Action.child .. ChildAction.modal) {
				Destinations()
			}
			.ifLet(\.$responseFailureAlert, action: /Action.view .. ViewAction.responseFailureAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await radixConnectClient.loadFromProfileAndConnectAll()
				let currentNetworkID = await gatewaysClient.getCurrentNetworkID()

				for try await incomingMessageResult in await radixConnectClient.receiveMessages() {
					guard !Task.isCancelled else {
						return
					}

					do {
						let interactionMessage = try incomingMessageResult.unwrapResult()
						let interaction = interactionMessage.peerMessage.content
						guard interaction.metadata.networkId == currentNetworkID else {
							let incomingRequestNetwork = try Network.lookupBy(id: interaction.metadata.networkId)
							let currentNetwork = try Network.lookupBy(id: currentNetworkID)
							let outMessage = interactionMessage.toOutgoingMessage(.failure(.init(
								interactionId: interaction.id,
								errorType: .wrongNetwork,
								message: L10n.DApp.Request.wrongNetworkError(incomingRequestNetwork.name, currentNetwork.name)
							)))

							try await radixConnectClient.sendMessage(outMessage)
							return
						}

						// TODO: uncomment and enable / disable based on developer mode preference
						/*
						 try await rolaClient.performDappDefinitionVerification(request.interaction.metadata)
						 try await rolaClient.performWellKnownFileCheck(request.interaction.metadata)
						 */
						await send(.internal(.receivedRequestFromDapp(interactionMessage)))
					} catch {
						loggerGlobal.error("Received message contans error: \(error.localizedDescription)")
						errorQueue.schedule(error)
					}
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .responseFailureAlert(action):
			switch action {
			case .dismiss:
				return .none
			case let .presented(.cancelButtonTapped(request)):
				dismissCurrentModalAndRequest(request, for: &state)
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			case let .presented(.retryButtonTapped(response, request, dappMetadata)):
				return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)
			}
		case .moveToBackground:
			return .fireAndForget {
				await radixConnectClient.disconnectAll()
			}
		case .moveToForeground:
			return .fireAndForget {
				await radixConnectClient.loadFromProfileAndConnectAll()
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .checkCanShowDappInteraction:
			if canShowInteraction() {
				return presentQueuedRequestIfNeededEffect(for: &state)
			} else {
				return delayedEffect(for: .internal(.checkCanShowDappInteraction))
			}
		case let .receivedRequestFromDapp(request):
			onPresent?()
			state.requestQueue.append(request)
			return .send(.internal(.checkCanShowDappInteraction))

		case .presentQueuedRequestIfNeeded:
			return .send(.internal(.checkCanShowDappInteraction))

		case let .sentResponseToDapp(response, for: request, dappMetadata):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return delayedEffect(
					for: .internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil)))
				)
			case .failure:
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}
		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return delayedEffect(for: .internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

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
			state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: next.peerMessage.content)))
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
			return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
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
		for request: P2P.RTCIncomingWalletInteraction,
		dappMetadata: DappMetadata?
	) -> EffectTask<Action> {
		.run { send in
			_ = try await radixConnectClient.sendMessage(response)
			await send(.internal(.sentResponseToDapp(response.peerMessage.content, for: request, dappMetadata)))
		} catch: { error, send in
			await send(.internal(.failedToSendResponseToDapp(response, for: request, dappMetadata, reason: error.localizedDescription)))
		}
	}

	func dismissCurrentModalAndRequest(_ request: P2P.RTCIncomingWalletInteraction, for state: inout State) {
		state.requestQueue.remove(request)
		state.currentModal = nil
		onDismiss?()
	}

	func delayedEffect(
		delay: Duration = .seconds(0.75),
		for action: Action
	) -> EffectTask<Action> {
		.run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}
