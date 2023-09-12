import AppPreferencesClient
import DappInteractionClient
import EngineKit
import FeaturePrelude
import GatewaysClient
import RadixConnect
import RadixConnectClient
import RadixConnectModels
import ROLAClient

typealias RequestEnvelope = DappInteractionClient.RequestEnvelope

// MARK: - DappInteractor
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<RequestEnvelope> = []

		@PresentationState
		var currentModal: Destinations.State?

		@PresentationState
		var responseFailureAlert: AlertState<ViewAction.ResponseFailureAlertAction>?

		@PresentationState
		var invalidRequestAlert: AlertState<ViewAction.InvalidRequestAlertAction>?
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case moveToBackground
		case moveToForeground
		case responseFailureAlert(PresentationAction<ResponseFailureAlertAction>)
		case invalidRequestAlert(PresentationAction<InvalidRequestAlertAction>)

		enum ResponseFailureAlertAction: Sendable, Hashable {
			case cancelButtonTapped(RequestEnvelope)
			case retryButtonTapped(P2P.Dapp.Response, for: RequestEnvelope, DappMetadata)
		}

		enum InvalidRequestAlertAction: Sendable, Hashable {
			case ok(P2P.RTCOutgoingMessage.Response, origin: P2P.Route)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(RequestEnvelope)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(
			P2P.Dapp.Response,
			for: RequestEnvelope,
			DappMetadata,
			TXID?
		)
		case failedToSendResponseToDapp(
			P2P.Dapp.Response,
			for: RequestEnvelope,
			DappMetadata,
			reason: String
		)
		case presentResponseFailureAlert(
			P2P.Dapp.Response,
			for: RequestEnvelope,
			DappMetadata, reason: String
		)
		case presentResponseSuccessView(DappMetadata, TXID?)
		case presentInvalidRequest(
			P2P.Dapp.RequestUnvalidated,
			reason: DappInteractionClient.ValidatedDappRequest.InvalidRequestReason,
			route: P2P.Route,
			isDeveloperModeEnabled: Bool
		)
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationAction<Destinations.Action>)
	}

	struct Destinations: Sendable, Reducer {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<RequestEnvelope, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<RequestEnvelope, DappInteractionCoordinator.Action>)
			case dappInteractionCompletion(Completion.Action)
		}

		var body: some ReducerOf<Self> {
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
	@Dependency(\.dappInteractionClient) var dappInteractionClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$currentModal, action: /Action.child .. ChildAction.modal) {
				Destinations()
			}
			.ifLet(\.$responseFailureAlert, action: /Action.view .. ViewAction.responseFailureAlert)
			.ifLet(\.$invalidRequestAlert, action: /Action.view .. ViewAction.invalidRequestAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

		case let .invalidRequestAlert(action):
			switch action {
			case .dismiss:
				return .none
			case let .presented(.ok(response, route)):
				return .run { send in
					do {
						try await dappInteractionClient.completeInteraction(.response(response, origin: route))
					} catch {
						errorQueue.schedule(error)
					}
					await send(.internal(.presentQueuedRequestIfNeeded))
				}
			}

		case .moveToBackground:
			return .run { _ in
				await radixConnectClient.disconnectAll()
			}
		case .moveToForeground:
			return .run { _ in
				_ = await radixConnectClient.loadFromProfileAndConnectAll()
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .receivedRequestFromDapp(request):

			switch state.currentModal {
			case .some(.dappInteractionCompletion):
				// FIXME: this is a temporary hack, to solve bug where incoming requests
				// are ignored since completion is believed to be shown, but is not.
				state.currentModal = nil
			default: break
			}

			if request.route == .wallet {
				// dismiss current request, wallet request takes precedence
				state.currentModal = nil
				state.requestQueue.insert(request, at: 0)
			} else {
				state.requestQueue.append(request)
			}

			return presentQueuedRequestIfNeededEffect(for: &state)

		case .presentQueuedRequestIfNeeded:
			return presentQueuedRequestIfNeededEffect(for: &state)

		case let .sentResponseToDapp(response, for: request, dappMetadata, txID):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return .send(.internal(.presentResponseSuccessView(dappMetadata, txID)))
			case .failure:
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

		case let .presentResponseFailureAlert(response, for: request, dappMetadata, reason):
			state.responseFailureAlert = .init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				actions: {
					ButtonState(role: .cancel, action: .cancelButtonTapped(request)) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .retryButtonTapped(response, for: request, dappMetadata)) {
						TextState(L10n.Common.retry)
					}
				},
				message: {
					#if DEBUG
					TextState(L10n.DAppRequest.ResponseFailureAlert.message + "\n\n" + reason)
					#else
					TextState(L10n.DAppRequest.ResponseFailureAlert.message)
					#endif
				}
			)
			return .none

		case let .presentInvalidRequest(invalidRequest, reason, route, isDeveloperModeEnabled):
			let response = P2P.Dapp.Response.WalletInteractionFailureResponse(
				interactionId: invalidRequest.id,
				errorType: reason.interactionResponseError,
				message: reason.explanation(isDeveloperModeEnabled)
			)

			state.invalidRequestAlert = .init(
				title: { TextState(L10n.Error.DappRequest.invalidRequest) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .ok(.dapp(.failure(response)), origin: route)
					) {
						TextState(L10n.Common.cancel)
					}
				},
				message: {
					let explanation = reason.explanation(isDeveloperModeEnabled)
					if explanation == reason.subtitle {
						return TextState(reason.subtitle)
					} else {
						return TextState(reason.subtitle + "\n" + explanation)
					}
				}
			)
			return .none

		case let .presentResponseSuccessView(dappMetadata, txID):
			state.currentModal = .dappInteractionCompletion(
				.init(
					txID: txID,
					dappMetadata: dappMetadata
				)
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submit(responseToDapp, dappMetadata)))))):
			return sendResponseToDappEffect(responseToDapp, for: request, dappMetadata: dappMetadata)
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.dismiss(dappMetadata, txID)))))):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseSuccessView(dappMetadata, txID)))

		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.dismissSilently))))):
			dismissCurrentModalAndRequest(request, for: &state)
			return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))

		case .modal(.dismiss):
			if case .dappInteractionCompletion = state.currentModal {
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

			return .none

		default:
			return .none
		}
	}

	func presentQueuedRequestIfNeededEffect(
		for state: inout State
	) -> Effect<Action> {
		guard
			let next = state.requestQueue.first,
			state.currentModal == nil
		else {
			return .none
		}
		state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: next.request)))

		return .none
	}

	func sendResponseToDappEffect(
		_ responseToDapp: P2P.Dapp.Response,
		for request: RequestEnvelope,
		dappMetadata: DappMetadata
	) -> Effect<Action> {
		.run { send in

			// In case of transaction response, sending it to the peer client is a silent operation.
			// The success or failures is determined based on the transaction polling status.
			let txID: TXID? = {
				if case let .success(successResponse) = responseToDapp,
				   case let .transaction(txID) = successResponse.items
				{
					return txID.send.transactionIntentHash
				}
				return nil
			}()
			let isTransactionResponse = txID != nil

			do {
				_ = try await dappInteractionClient.completeInteraction(.response(.dapp(responseToDapp), origin: request.route))
				if !isTransactionResponse {
					await send(.internal(
						.sentResponseToDapp(
							responseToDapp,
							for: request,
							dappMetadata,
							txID
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

	func dismissCurrentModalAndRequest(_ request: RequestEnvelope, for state: inout State) {
		state.requestQueue.remove(request)
		state.currentModal = nil
	}
}

extension DappInteractionClient.ValidatedDappRequest.InvalidRequestReason {
	var interactionResponseError: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType {
		switch self {
		case .incompatibleVersion:
			return .incompatibleVersion
		case .wrongNetworkID:
			return .wrongNetwork
		case .invalidDappDefinitionAddress:
			return .unknownDappDefinitionAddress
		case .invalidOrigin:
			return .invalidOriginURL
		case .dAppValidationError:
			return .unknownDappDefinitionAddress
		case .badContent:
			return .invalidRequest
		}
	}

	var subtitle: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return L10n.DAppRequest.ValidationOutcome.subtitleBadContent
		case .incompatibleVersion:
			return L10n.DAppRequest.ValidationOutcome.subtitleIncompatibleVersion
		case .wrongNetworkID:
			return L10n.DAppRequest.ValidationOutcome.subtitleWrongNetworkID
		case .invalidOrigin, .invalidDappDefinitionAddress, .dAppValidationError:
			return shortExplanation
		}
	}

	func explanation(_ isDeveloperModeEnabled: Bool) -> String {
		if isDeveloperModeEnabled {
			return detailedExplanationForDevelopers
		}
		#if DEBUG
		return detailedExplanationForDevelopers
		#else
		return shortExplanation
		#endif
	}

	private var detailedExplanationForDevelopers: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return L10n.DAppRequest.ValidationOutcome.devExplanationBadContent
		case let .incompatibleVersion(ce, wallet):
			return L10n.DAppRequest.ValidationOutcome.devExplanationIncompatibleVersion(shortExplanation, ce, wallet)
		case let .invalidOrigin(invalidURLString):
			return L10n.DAppRequest.ValidationOutcome.devExplanationInvalidOrigin(invalidURLString)
		case let .invalidDappDefinitionAddress(invalidAddress):
			return L10n.DAppRequest.ValidationOutcome.devExplanationInvalidDappDefinitionAddress(invalidAddress)
		case .dAppValidationError, .wrongNetworkID:
			return shortExplanation
		}
	}

	private var shortExplanation: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return L10n.DAppRequest.ValidationOutcome.shortExplanationBadContent
		case let .incompatibleVersion(ce, wallet):
			if ce > wallet {
				return L10n.DAppRequest.ValidationOutcome.shortExplanationIncompatibleVersionCEGreater
			} else {
				return L10n.DAppRequest.ValidationOutcome.shortExplanationIncompatibleVersionCENotGreater
			}
		case .invalidOrigin:
			return L10n.DAppRequest.ValidationOutcome.shortExplanationInvalidOrigin
		case .invalidDappDefinitionAddress:
			return L10n.DAppRequest.ValidationOutcome.shortExplanationInvalidDappDefinitionAddress
		case .dAppValidationError:
			return "Could not validate the dApp" // FIXME: Strings
		case let .wrongNetworkID(ce, wallet):
			return L10n.DAppRequest.RequestWrongNetworkAlert.message(ce, wallet)
		}
	}
}

extension DappInteractor {
	func handleIncomingRequests() -> Effect<Action> {
		.run { send in
			for try await incomingRequest in dappInteractionClient.interactions {
				guard !Task.isCancelled else {
					return
				}

				do {
					let validatedRequest = try incomingRequest.get()
					switch validatedRequest.request {
					case let .valid(request):
						await send(.internal(.receivedRequestFromDapp(.init(route: validatedRequest.route, request: request))))
					case let .invalid(invalidRequest, reason):
						let isDeveloperModeEnabled = await appPreferencesClient.isDeveloperModeEnabled()
						await send(.internal(.presentInvalidRequest(
							invalidRequest,
							reason: reason,
							route: validatedRequest.route,
							isDeveloperModeEnabled: isDeveloperModeEnabled
						)))
					}
				} catch {
					errorQueue.schedule(error)
				}
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func delayedEffect(
		delay: Duration = .seconds(0.75),
		for action: Action
	) -> Effect<Action> {
		.run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}
