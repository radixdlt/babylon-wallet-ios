import AppPreferencesClient
import FeaturePrelude
import GatewaysClient
import RadixConnect
import RadixConnectClient
import RadixConnectModels
import ROLAClient

// MARK: - RequestEnvelop
struct RequestEnvelop: Sendable, Hashable {
	let route: P2P.RTCRoute
	let request: P2P.Dapp.Request
}

// MARK: - DappInteractor
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<RequestEnvelop> = []

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
			case cancelButtonTapped(RequestEnvelop)
			case retryButtonTapped(P2P.Dapp.Response, for: RequestEnvelop, DappContext)
		}

		enum InvalidRequestAlertAction: Sendable, Hashable {
			case ok
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(RequestEnvelop)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.Dapp.Response, for: RequestEnvelop, DappContext)
		case failedToSendResponseToDapp(P2P.Dapp.Response, for: RequestEnvelop, DappContext, reason: String)
		case presentResponseFailureAlert(P2P.Dapp.Response, for: RequestEnvelop, DappContext, reason: String)
		case presentResponseSuccessView(DappContext)
		case presentInvalidRequest(DappRequestValidationOutcome.Invalid, isDeveloperModeEnabled: Bool)
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationAction<Destinations.Action>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<RequestEnvelop, DappInteractionCoordinator.State>)
			case dappInteractionCompletion(Completion.State)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<RequestEnvelop, DappInteractionCoordinator.Action>)
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
			.ifLet(\.$invalidRequestAlert, action: /Action.view .. ViewAction.invalidRequestAlert)
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
			case let .presented(.retryButtonTapped(response, request, dappContext)):
				return sendResponseToDappEffect(response, for: request, dappContext: dappContext)
			}

		case let .invalidRequestAlert(action):
			switch action {
			case .dismiss:
				return .none
			case .presented(.ok):
				return .send(.internal(.presentQueuedRequestIfNeeded))
			}

		case .moveToBackground:
			return .fireAndForget {
				await radixConnectClient.disconnectAll()
			}
		case .moveToForeground:
			return .fireAndForget {
				_ = await radixConnectClient.loadFromProfileAndConnectAll()
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

		case let .sentResponseToDapp(response, for: request, dappContext):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				return .send(.internal(.presentResponseSuccessView(dappContext)))
			case .failure:
				return delayedEffect(for: .internal(.presentQueuedRequestIfNeeded))
			}

		case let .failedToSendResponseToDapp(response, for: request, metadata, reason):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseFailureAlert(response, for: request, metadata, reason: reason)))

		case let .presentResponseFailureAlert(response, for: request, dappContext, reason):
			state.responseFailureAlert = .init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				actions: {
					ButtonState(role: .cancel, action: .cancelButtonTapped(request)) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .retryButtonTapped(response, for: request, dappContext)) {
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

		case let .presentInvalidRequest(invalidReason, isDeveloperModeEnabled):
			state.invalidRequestAlert = .init(
				title: { TextState("Invalid request") },
				actions: {
					ButtonState(role: .cancel, action: .ok) {
						TextState(L10n.Common.cancel)
					}
				},
				message: { TextState(invalidReason.subtitle + "\n" + invalidReason.explaination(isDeveloperModeEnabled)) }
			)
			return .none

		case let .presentResponseSuccessView(dappContext):
			state.currentModal = .dappInteractionCompletion(.init(dappContext: dappContext))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submit(responseToDapp, dappContext)))))):
			return sendResponseToDappEffect(responseToDapp, for: request, dappContext: dappContext)
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.dismiss(dappContext)))))):
			dismissCurrentModalAndRequest(request, for: &state)
			return .send(.internal(.presentResponseSuccessView(dappContext)))
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
		state.currentModal = .dappInteraction(.relayed(next, with: .init(interaction: next.request)))

		return .none
	}

	func sendResponseToDappEffect(
		_ responseToDapp: P2P.Dapp.Response,
		for request: RequestEnvelop,
		dappContext: DappContext
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
							dappContext
						)
					))
				}
			} catch {
				if !isTransactionResponse {
					await send(.internal(
						.failedToSendResponseToDapp(
							responseToDapp,
							for: request,
							dappContext,
							reason: error.localizedDescription
						)
					))
				}
			}
		}
	}

	func dismissCurrentModalAndRequest(_ request: RequestEnvelop, for state: inout State) {
		state.requestQueue.remove(request)
		state.currentModal = nil
	}
}

// MARK: - DappRequestValidationOutcome
enum DappRequestValidationOutcome: Sendable, Hashable {
	case valid(RequestEnvelop)
	case invalid(Invalid)
	enum Invalid: Sendable, Hashable {
		case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
		case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
		case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
		case invalidOrigin(invalidURLString: String)
		case badContent(BadContent)
		enum BadContent: Sendable, Hashable {
			case numberOfAccountsInvalid
		}
	}
}

extension DappRequestValidationOutcome.Invalid {
	var subtitle: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return "Invalid content"
		case .incompatibleVersion:
			return "Incompatible connector extension"
		case .invalidOrigin:
			return "Invalid origin"
		case .invalidDappDefinitionAddress:
			return "Invalid dAppDefinitionAddress"
		case .wrongNetworkID:
			return "Network mismatch"
		}
	}

	func explaination(_ isDeveloperModeEnabled: Bool) -> String {
		if isDeveloperModeEnabled {
			return detailedExplainationForDevelopers
		}
		#if DEBUG
		return detailedExplainationForDevelopers
		#else
		return shortExplaination
		#endif
	}

	private var detailedExplainationForDevelopers: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return "Invalid value of `numberOfAccountsInvalid`: must not be be `exactly(0)` nor can `quantity` be negative"
		case let .incompatibleVersion(ce, wallet):
			return shortExplaination + " (CE: \(ce), wallet: \(wallet))"
		case let .invalidDappDefinitionAddress(invalidAddress):
			return "'\(invalidAddress)' is not valid account address."
		case let .invalidOrigin(invalidURLString):
			return "'\(invalidURLString)' is not valid origin."
		case .wrongNetworkID:
			return shortExplaination
		}
	}

	private var shortExplaination: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return "Invalid data in request"
		case let .incompatibleVersion(ce, wallet):
			return ce > wallet ? "Update Wallet" : "Update Connector Extension"
		case .invalidDappDefinitionAddress:
			return "Invalid dAppDefinitionAddress"
		case .invalidOrigin:
			return "Invalid origin"
		case let .wrongNetworkID(ce, wallet):
			return L10n.DAppRequest.RequestWrongNetworkAlert.message(ce, wallet)
		}
	}
}

extension DappInteractor {
	/// Validates a received request from Dapp.
	func validate(
		_ nonValidated: P2P.Dapp.RequestUnvalidated,
		route: P2P.RTCRoute
	) async -> (outcome: DappRequestValidationOutcome, isDeveloperModeEnabled: Bool) {
		let nonvalidatedMeta = nonValidated.metadata
		let isDeveloperModeEnabled = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled
		let outcome: DappRequestValidationOutcome = await {
			guard P2P.Dapp.currentVersion == nonvalidatedMeta.version else {
				return .invalid(.incompatibleVersion(connectorExtensionSent: nonvalidatedMeta.version, walletUses: P2P.Dapp.currentVersion))
			}
			let currentNetworkID = await gatewaysClient.getCurrentNetworkID()
			guard currentNetworkID == nonValidated.metadata.networkId else {
				return .invalid(.wrongNetworkID(connectorExtensionSent: nonvalidatedMeta.networkId, walletUses: currentNetworkID))
			}

			let dappDefinitionAddress: DappDefinitionAddress
			do {
				dappDefinitionAddress = try DappDefinitionAddress(
					address: nonValidated.metadata.dAppDefinitionAddress
				)
			} catch {
				return .invalid(.invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: nonvalidatedMeta.dAppDefinitionAddress))
			}

			if case let .request(readRequest) = nonValidated.items {
				switch readRequest {
				case let .authorized(authorized):
					if authorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
					if authorized.ongoingAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
				case let .unauthorized(unauthorized):
					if unauthorized.oneTimeAccounts?.numberOfAccounts.isValid == false {
						return .invalid(.badContent(.numberOfAccountsInvalid))
					}
				}
			}

			guard
				let originURL = URL(string: nonvalidatedMeta.origin),
				let nonEmptyOriginURLString = NonEmptyString(rawValue: nonvalidatedMeta.origin)
			else {
				return .invalid(.invalidOrigin(invalidURLString: nonvalidatedMeta.origin))
			}
			let origin = DappOrigin(urlString: nonEmptyOriginURLString, url: originURL)

			let metadataValidDappDefAddres = P2P.Dapp.Request.Metadata(
				version: nonvalidatedMeta.version,
				networkId: nonvalidatedMeta.networkId,
				origin: origin,
				dAppDefinitionAddress: dappDefinitionAddress
			)

			return .valid(.init(
				route: route,
				request: .init(
					id: nonValidated.id,
					items: nonValidated.items,
					metadata: metadataValidDappDefAddres
				)
			))
		}()

		return (outcome, isDeveloperModeEnabled)
	}

	func handleIncomingRequests() -> EffectTask<Action> {
		.run { send in
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}
				do {
					let requestToValidate = try incomingRequest.result.get()
					let validation = await validate(requestToValidate, route: incomingRequest.route)
					switch validation.outcome {
					case let .valid(requestEnvelop):
						await send(.internal(.receivedRequestFromDapp(
							requestEnvelop
						)))

					case let .invalid(invalid):
						await send(.internal(.presentInvalidRequest(invalid, isDeveloperModeEnabled: validation.isDeveloperModeEnabled)))
					}
				} catch {
					loggerGlobal.error("Received message contans error: \(error.localizedDescription)")
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
	) -> EffectTask<Action> {
		.run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}
