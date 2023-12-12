import ComposableArchitecture
import SwiftUI
typealias RequestEnvelope = DappInteractionClient.RequestEnvelope

// MARK: Identifiable
extension RequestEnvelope: Identifiable {
	public typealias ID = P2P.Dapp.Request.ID
	public var id: ID {
		request.id
	}
}

// MARK: - DappInteractor
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: IdentifiedArrayOf<RequestEnvelope> = []

		@PresentationState
		var currentModal: Modal.State?

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
		case modal(PresentationAction<Modal.Action>)
	}

	struct Modal: Sendable, Reducer {
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
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$currentModal, action: /Action.child .. ChildAction.modal) {
				Modal()
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
				return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
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
				message: reason.responseMessage()
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
				message: { TextState(reason.alertMessage(isDeveloperModeEnabled)) }
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
			return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)

		case .modal(.dismiss):
			if case .dappInteractionCompletion = state.currentModal {
				return delayedMediumEffect(internal: .presentQueuedRequestIfNeeded)
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
		state.currentModal = nil
	}
}

extension DappInteractionClient.ValidatedDappRequest.InvalidRequestReason {
	var interactionResponseError: P2P.Dapp.Response.WalletInteractionFailureResponse.ErrorType {
		switch self {
		case .incompatibleVersion:
			.incompatibleVersion
		case .wrongNetworkID:
			.wrongNetwork
		case .invalidDappDefinitionAddress:
			.unknownDappDefinitionAddress
		case .invalidOrigin:
			.invalidOriginURL
		case .dAppValidationError:
			.unknownDappDefinitionAddress
		case .badContent:
			.invalidRequest
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
		case .invalidOrigin, .invalidDappDefinitionAddress, .dAppValidationError:
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
		case .wrongNetworkID:
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
		}
	}

	private func networkName(for networkID: NetworkID) -> String {
		(try? Radix.Network.lookupBy(id: networkID).name.rawValue) ?? String(describing: networkID)
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
}
