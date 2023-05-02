import AppPreferencesClient
import FeaturePrelude
import GatewaysClient
import RadixConnect
import RadixConnectClient
import ROLAClient

// MARK: - DappInteractionHook
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RTCIncomingDappRequest> = []

		@PresentationState
		var currentModal: Destinations.State?
		@PresentationState
		var responseFailureAlert: AlertState<ViewAction.ResponseFailureAlertAction>?
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case moveToBackground
		case moveToForeground
		case responseFailureAlert(PresentationAction<ResponseFailureAlertAction>)

		enum ResponseFailureAlertAction: Sendable, Hashable {
			case cancelButtonTapped(P2P.RTCIncomingDappRequest)
			case retryButtonTapped(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RTCIncomingDappRequest)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?)
		case failedToSendResponseToDapp(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?, reason: String)
		case presentResponseFailureAlert(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?, reason: String)
		case presentResponseSuccessView(DappMetadata)
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationAction<Destinations.Action>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<P2P.RTCIncomingDappRequest, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<P2P.RTCIncomingDappRequest, DappInteractionCoordinator.Action>)
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

	var canShowInteraction: @Sendable () -> Bool = { true }

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

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
			return handleIncomingRequests()
		case let .responseFailureAlert(action):
			switch action {
			case .dismiss:
				return .none
			case let .presented(.cancelButtonTapped(request)):
				dismissCurrentModalAndRequest(request, for: &state)
				return .send(.internal(.presentQueuedRequestIfNeeded))
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
		case let .receivedRequestFromDapp(request):
			state.requestQueue.append(request)
			return presentQueuedRequestIfNeededEffect(for: &state)

		case .presentQueuedRequestIfNeeded:
			return presentQueuedRequestIfNeededEffect(for: &state)

		case let .sentResponseToDapp(response, for: request, dappMetadata):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return .send(.internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil))))
			case .failure:
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

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
				message: {
					TextState(
						L10n.DApp.Response.FailureAlert.message + {
							#if DEBUG
							"\n\n" + reason
							#else
							""
							#endif
						}()
					)
				}
			)
			return .none

		case let .presentResponseSuccessView(dappMetadata):
			state.currentModal = .dappInteractionCompletion(.init(dappMetadata: dappMetadata))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submit(responseToDapp, dappMetadata)))))):
			return sendResponseToDappEffect(responseToDapp, for: request, dappMetadata: dappMetadata)
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.dismiss(dappMetadata)))))):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil))))
		case .modal(.presented(.dappInteractionCompletion(.delegate(.dismiss)))):
			state.currentModal = nil
			return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
		default:
			return .none
		}
	}

	func presentQueuedRequestIfNeededEffect(
		for state: inout State
	) -> EffectTask<Action> {
		guard
			let next = state.requestQueue.first,
			state.currentModal == nil
		else {
			return .none
		}

		do {
			let nextRequest = try next.result.get()
			state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: nextRequest)))
		} catch {
			let errorMsg = "Unexpectedly unwrapped error when handling next wallet interaction."
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
		}

		return .none
	}

	func sendResponseToDappEffect(
		_ responseToDapp: P2P.Dapp.Response,
		for request: P2P.RTCIncomingDappRequest,
		dappMetadata: DappMetadata?
	) -> EffectTask<Action> {
		.run { send in

			// In case of transaction response, sending it to the peer client is a silent operation.
			// The success or failures is determined based on the transaction polling status.
			let isTransactionResponse = {
				if case let .success(successResponse) = responseToDapp,
				   case .transaction = successResponse.items
				{
					return true
				}
				return false
			}()

			do {
				_ = try await radixConnectClient.sendResponse(.dapp(responseToDapp), request.route)
				if !isTransactionResponse {
					await send(.internal(
						.sentResponseToDapp(
							responseToDapp,
							for: request,
							dappMetadata
						)
					))
				}
			} catch {
				if !isTransactionResponse {
					await send(.internal(
						.failedToSendResponseToDapp(
							responseToDapp,
							for: request,
							dappMetadata,
							reason: error.localizedDescription
						)
					))
				}
			}
		}
	}

	func dismissCurrentModalAndRequest(_ request: P2P.RTCIncomingDappRequest, for state: inout State) {
		state.requestQueue.remove(request)
		state.currentModal = nil
	}

	func handleIncomingRequests() -> EffectTask<Action> {
		.run { send in
			_ = await radixConnectClient.loadFromProfileAndConnectAll()
			let currentNetworkID = await gatewaysClient.getCurrentNetworkID()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}

				do {
					let request = try incomingRequest.result.get()
					try validate(request)

					guard request.metadata.networkId == currentNetworkID else {
						let incomingRequestNetwork = try Radix.Network.lookupBy(id: request.metadata.networkId)
						let currentNetwork = try Radix.Network.lookupBy(id: currentNetworkID)

						try await radixConnectClient.sendResponse(.dapp(.failure(.init(
							interactionId: request.id,
							errorType: .wrongNetwork,
							message: L10n.DApp.Request.wrongNetworkError(incomingRequestNetwork.name, currentNetwork.name)
						))), incomingRequest.route)
						continue
					}

					let isDeveloperModeEnabled = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled.rawValue
					if !isDeveloperModeEnabled {
						try await rolaClient.performDappDefinitionVerification(request.metadata)
						try await rolaClient.performWellKnownFileCheck(request.metadata)
					}
					await send(.internal(.receivedRequestFromDapp(incomingRequest)))
				} catch {
					loggerGlobal.error("Received message contans error: \(error.localizedDescription)")
					errorQueue.schedule(error)
				}
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func validate(_ interaction: P2P.Dapp.Request) throws {
		switch interaction.items {
		case let .request(items):
			switch items {
			case let .unauthorized(unauthorized):
				if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
					throw P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType.invalidRequest
				}
			case let .authorized(authorized):
				if authorized.ongoingAccounts?.numberOfAccounts.isValid == false ||
					authorized.oneTimeAccounts?.numberOfAccounts.isValid == false
				{
					throw P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType.invalidRequest
				}
			}
		case .transaction:
			return
		}
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
