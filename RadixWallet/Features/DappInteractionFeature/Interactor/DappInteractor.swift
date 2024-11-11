import ComposableArchitecture
import Sargon
import SwiftUI

typealias RequestEnvelope = DappInteractionClient.RequestEnvelope

// MARK: Identifiable
extension RequestEnvelope: Identifiable {
	typealias ID = WalletInteractionId
	var id: ID {
		interaction.interactionId
	}
}

// MARK: - DappInteractor
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: IdentifiedArrayOf<RequestEnvelope> = []

		@PresentationState
		var destination: Destination.State?

		fileprivate var shouldIncrementOnCompletionDismiss = false
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case moveToBackground
		case moveToForeground
		case completionDismissed
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(RequestEnvelope)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(
			WalletToDappInteractionResponse,
			for: RequestEnvelope,
			DappMetadata,
			TransactionIntentHash?
		)
		case failedToSendResponseToDapp(
			WalletToDappInteractionResponse,
			for: RequestEnvelope,
			DappMetadata,
			reason: String
		)
		case presentResponseFailureAlert(
			WalletToDappInteractionResponse,
			for: RequestEnvelope,
			DappMetadata, reason: String
		)
		case presentResponseSuccessView(DappMetadata, TransactionIntentHash?, P2P.Route)
		case presentInvalidRequest(
			DappToWalletInteractionUnvalidated,
			reason: DappInteractionClient.ValidatedDappRequest.InvalidRequestReason,
			route: P2P.Route,
			isDeveloperModeEnabled: Bool
		)
	}

	struct Destination: Sendable, DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case dappInteraction(DappInteractionCoordinator.State)
			case dappInteractionCompletion(Completion.State)
			case responseFailure(AlertState<Action.ResponseFailure>)
			case invalidRequest(AlertState<Action.InvalidRequest>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case dappInteraction(DappInteractionCoordinator.Action)
			case dappInteractionCompletion(Completion.Action)
			case responseFailure(ResponseFailure)
			case invalidRequest(InvalidRequest)

			enum ResponseFailure: Sendable, Hashable {
				case cancelButtonTapped(RequestEnvelope)
				case retryButtonTapped(WalletToDappInteractionResponse, for: RequestEnvelope, DappMetadata)
			}

			enum InvalidRequest: Sendable, Hashable {
				case ok(P2P.RTCOutgoingMessage.Response, origin: P2P.Route)
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.dappInteraction, action: \.dappInteraction) {
				DappInteractionCoordinator()
			}
			Scope(state: \.dappInteractionCompletion, action: \.dappInteractionCompletion) {
				Completion()
			}
		}
	}

	var canShowInteraction: @Sendable () -> Bool = { true }

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.npsSurveyClient) var npsSurveyClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return handleIncomingRequests()

		case .moveToBackground:
			return .run { _ in
				await radixConnectClient.disconnectAll()
			}

		case .moveToForeground:
			return .run { _ in
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
			}

		case .completionDismissed:
			if state.shouldIncrementOnCompletionDismiss {
				npsSurveyClient.incrementTransactionCompleteCounter()
			}
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .receivedRequestFromDapp(request):

			switch state.destination {
			case .some(.dappInteractionCompletion):
				if state.requestQueue.isEmpty {
					state.destination = nil
				}
			default: break
			}

			state.requestQueue.append(request)

			return presentQueuedRequestIfNeededEffect(for: &state)

		case .presentQueuedRequestIfNeeded:
			return presentQueuedRequestIfNeededEffect(for: &state)

		case let .sentResponseToDapp(response, for: request, dappMetadata, txID):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return .send(.internal(.presentResponseSuccessView(dappMetadata, txID, request.route)))
			case .failure:
				return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
			}

		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

		case let .presentResponseFailureAlert(response, for: request, dappMetadata, reason):
			state.destination = .responseFailure(.init(
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
			))

			return .none

		case let .presentInvalidRequest(invalidRequest, reason, route, isDeveloperModeEnabled):
			let response = WalletToDappInteractionFailureResponse(
				interactionId: invalidRequest.interactionId,
				error: reason.interactionResponseError,
				message: reason.responseMessage()
			)

			state.destination = .invalidRequest(.init(
				title: { TextState(L10n.Error.DappRequest.invalidRequest) },
				actions: {
					ButtonState(
						role: .cancel,
						action: .ok(.dapp(.failure(response)), origin: route)
					) {
						TextState(L10n.Common.cancel)
					}
				},
				message: { TextState(reason.alertMessage(isDeveloperModeEnabled)) }
			))
			return .none

		case let .presentResponseSuccessView(dappMetadata, txID, p2pRoute):
			state.shouldIncrementOnCompletionDismiss = txID != nil
			if !state.requestQueue.isEmpty {
				return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
			}
			state.destination = .dappInteractionCompletion(
				.init(
					txID: txID,
					dappMetadata: dappMetadata,
					p2pRoute: p2pRoute
				)
			)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .dappInteraction(.delegate(delegateAction)):
			guard case let .dappInteraction(dappInteraction) = state.destination else {
				let message = "We should only get actions from this modal if it is showing"
				assertionFailure(message)
				loggerGlobal.error(.init(stringLiteral: message))
				return .none
			}
			let request = dappInteraction.request

			switch delegateAction {
			case let .submit(responseToDapp, dappMetadata):
				return sendResponseToDappEffect(responseToDapp, for: request, dappMetadata: dappMetadata)
			case let .dismiss(dappMetadata, txID):
				dismissCurrentModalAndRequest(request, for: &state)
				return delayedShortEffect(for: .internal(.presentResponseSuccessView(dappMetadata, txID, request.route)))
			case .dismissSilently:
				dismissCurrentModalAndRequest(request, for: &state)
				return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
			}

		case .dappInteractionCompletion(.delegate(.dismiss)):
			return onCompletionScreenDismissed(&state)

		case let .responseFailure(action):
			switch action {
			case let .cancelButtonTapped(request):
				dismissCurrentModalAndRequest(request, for: &state)
				return .send(.internal(.presentQueuedRequestIfNeeded))
			case let .retryButtonTapped(response, request, dappMetadata):
				return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)
			}

		case let .invalidRequest(action):
			switch action {
			case let .ok(response, route):
				return .run { send in
					do {
						try await dappInteractionClient.completeInteraction(.response(response, origin: route))
					} catch {
						errorQueue.schedule(error)
					}
					await send(.internal(.presentQueuedRequestIfNeeded))
				}
			}

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		switch state.destination {
		case .dappInteractionCompletion:
			onCompletionScreenDismissed(&state)
		default:
			.none
		}
	}

	func presentQueuedRequestIfNeededEffect(
		for state: inout State
	) -> Effect<Action> {
		guard
			let next = state.requestQueue.first,
			state.destination == nil
		else {
			return .none
		}

		state.destination = .dappInteraction(.init(request: next))

		return .none
	}

	func sendResponseToDappEffect(
		_ responseToDapp: WalletToDappInteractionResponse,
		for request: RequestEnvelope,
		dappMetadata: DappMetadata
	) -> Effect<Action> {
		.run { send in

			// In case of transaction response, sending it to the peer client is a silent operation.
			// The success or failures is determined based on the transaction polling status.
			let txID: TransactionIntentHash? = {
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
				} else {
					loggerGlobal.notice("Not delegating to `sentResponseToDapp`")
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
				} else {
					loggerGlobal.notice("Failed to send response back to dapp, error: \(error), not delegating `sentResponseToDapp`.")
				}
			}
		}
	}

	func dismissCurrentModalAndRequest(_ request: RequestEnvelope, for state: inout State) {
		state.requestQueue.remove(id: request.id)
		state.destination = nil
	}

	func onCompletionScreenDismissed(_ state: inout State) -> Effect<Action> {
		state.destination = nil
		return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
	}
}

extension DappInteractionClient.ValidatedDappRequest.InvalidRequestReason {
	var interactionResponseError: DappWalletInteractionErrorType {
		switch self {
		case .incompatibleVersion:
			.incompatibleVersion
		case .wrongNetworkID:
			.wrongNetwork
		case .invalidDappDefinitionAddress:
			.unknownDappDefinitionAddress
		case .invalidOrigin:
			.invalidOriginUrl
		case .dAppValidationError:
			.unknownDappDefinitionAddress
		case .badContent:
			.invalidRequest
		case .invalidPersonaOrAccounts:
			.invalidPersonaOrAccounts
		case .invalidPreAuthorization(.expirationTooClose):
			.subintentExpirationTooClose
		case .invalidPreAuthorization(.expired):
			.expiredSubintent
		}
	}

	func responseMessage() -> String {
		detailedExplanationForDevelopers
	}

	func alertMessage(_ isDeveloperModeEnabled: Bool) -> String {
		let explanation = explanation(isDeveloperModeEnabled)
		if explanation.hasPrefix(subtitle) {
			return explanation
		} else {
			return subtitle + "\n" + explanation
		}
	}

	private var subtitle: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			L10n.DAppRequest.ValidationOutcome.subtitleBadContent
		case .incompatibleVersion:
			L10n.DAppRequest.ValidationOutcome.subtitleIncompatibleVersion
		case .wrongNetworkID:
			L10n.DAppRequest.ValidationOutcome.subtitleWrongNetworkID
		case .invalidOrigin, .invalidDappDefinitionAddress, .dAppValidationError, .invalidPersonaOrAccounts, .invalidPreAuthorization:
			shortExplanation
		}
	}

	private func explanation(_ isDeveloperModeEnabled: Bool) -> String {
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
			L10n.DAppRequest.ValidationOutcome.devExplanationBadContent
		case let .incompatibleVersion(ce, wallet):
			L10n.DAppRequest.ValidationOutcome.devExplanationIncompatibleVersion(shortExplanation, ce, wallet)
		case let .invalidOrigin(invalidURLString):
			L10n.DAppRequest.ValidationOutcome.devExplanationInvalidOrigin(invalidURLString)
		case let .invalidDappDefinitionAddress(invalidAddress):
			L10n.DAppRequest.ValidationOutcome.devExplanationInvalidDappDefinitionAddress(invalidAddress)
		case let .dAppValidationError(underlyingError):
			"\(L10n.DAppRequest.ValidationOutcome.invalidRequestMessage): \(underlyingError)"
		case .wrongNetworkID, .invalidPersonaOrAccounts, .invalidPreAuthorization:
			shortExplanation
		}
	}

	private var shortExplanation: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			L10n.DAppRequest.ValidationOutcome.shortExplanationBadContent
		case let .incompatibleVersion(ce, wallet):
			if ce > wallet {
				L10n.DAppRequest.ValidationOutcome.shortExplanationIncompatibleVersionCEGreater
			} else {
				L10n.DAppRequest.ValidationOutcome.shortExplanationIncompatibleVersionCENotGreater
			}
		case .invalidOrigin:
			L10n.DAppRequest.ValidationOutcome.shortExplanationInvalidOrigin
		case .invalidDappDefinitionAddress:
			L10n.DAppRequest.ValidationOutcome.shortExplanationInvalidDappDefinitionAddress
		case .dAppValidationError:
			L10n.DAppRequest.ValidationOutcome.invalidRequestMessage
		case let .wrongNetworkID(ce, wallet):
			L10n.DAppRequest.RequestWrongNetworkAlert.message(networkName(for: ce), networkName(for: wallet))
		case .invalidPersonaOrAccounts:
			L10n.DAppRequest.ValidationOutcome.invalidPersonaOrAccoubts
		case .invalidPreAuthorization(.expirationTooClose):
			L10n.DAppRequest.ValidationOutcome.preAuthorizationExpirationTooClose
		case .invalidPreAuthorization(.expired):
			L10n.DAppRequest.ValidationOutcome.preAuthorizationExpired
		}
	}

	private func networkName(for networkID: NetworkID) -> String {
		Gateway.forNetwork(id: networkID).network.displayDescription
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
						await send(.internal(.receivedRequestFromDapp(.init(
							route: validatedRequest.route,
							interaction: request,
							requiresOriginValidation: validatedRequest.requiresOriginVerification
						))))
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
}
