import AppPreferencesClient
import DappInteractionClient
import FeaturePrelude
import GatewaysClient
import OverlayWindowClient
import RadixConnect
import RadixConnectClient
import RadixConnectModels
import ROLAClient

import EngineToolkit

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
			case ok
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(RequestEnvelope)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.Dapp.Response, for: RequestEnvelope, DappMetadata)
		case failedToSendResponseToDapp(P2P.Dapp.Response, for: RequestEnvelope, DappMetadata, reason: String)
		case presentResponseFailureAlert(P2P.Dapp.Response, for: RequestEnvelope, DappMetadata, reason: String)
		case presentInvalidRequest(DappInteractionClient.ValidatedDappRequest.Invalid, isDeveloperModeEnabled: Bool)
	}

	enum ChildAction: Sendable, Equatable {
		case modal(PresentationAction<Destinations.Action>)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case dappInteraction(RelayState<RequestEnvelope, DappInteractionCoordinator.State>)
		}

		enum Action: Sendable, Equatable {
			case dappInteraction(RelayAction<RequestEnvelope, DappInteractionCoordinator.Action>)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.dappInteraction, action: /Action.dappInteraction) {
				Relay { DappInteractionCoordinator() }
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
	@Dependency(\.overlayWindowClient) var overlayWindowClient

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
			case let .presented(.retryButtonTapped(response, request, dappMetadata)):
				return sendResponseToDappEffect(response, for: request, dappMetadata: dappMetadata)
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

		case let .sentResponseToDapp(response, for: request, dappMetadata):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				if case let .success(success) = response, case let .transaction(tx) = success.items {
					overlayWindowClient.scheduleTransactionPoll(.init(
						txID: tx.send.transactionIntentHash,
						disableInProgressDismissal: response.id.isAccountDepositSettingsInteraction
					))
				} else {
					overlayWindowClient.scheduleDappInteractionSuccess(.init(dappName: dappMetadata.name))
				}
				return presentQueuedRequestIfNeededEffect(for: &state)
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

		case let .presentInvalidRequest(invalidReason, isDeveloperModeEnabled):
			state.invalidRequestAlert = .init(
				title: { TextState(L10n.Error.DappRequest.invalidRequest) },
				actions: {
					ButtonState(role: .cancel, action: .ok) {
						TextState(L10n.Common.cancel)
					}
				},
				message: { TextState(invalidReason.subtitle + "\n" + invalidReason.explanation(isDeveloperModeEnabled)) }
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submit(responseToDapp, dappMetadata)))))):
			return sendResponseToDappEffect(responseToDapp, for: request, dappMetadata: dappMetadata)
		case .modal(.dismiss):
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
		for request: RequestEnvelope,
		dappMetadata: DappMetadata
	) -> EffectTask<Action> {
		.run { send in
			do {
				_ = try await dappInteractionClient.completeInteraction(.response(.dapp(responseToDapp), origin: request.route))
				await send(.internal(
					.sentResponseToDapp(
						responseToDapp,
						for: request,
						dappMetadata
					)
				))
			} catch {
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

	func dismissCurrentModalAndRequest(_ request: RequestEnvelope, for state: inout State) {
		print("dismissed current modal")
		state.requestQueue.remove(request)
		state.currentModal = nil
	}
}

extension DappInteractionClient.ValidatedDappRequest.Invalid {
	var subtitle: String {
		switch self {
		case .badContent(.numberOfAccountsInvalid):
			return L10n.DAppRequest.ValidationOutcome.subtitleBadContent
		case .incompatibleVersion:
			return L10n.DAppRequest.ValidationOutcome.subtitleIncompatibleVersion
		case .wrongNetworkID:
			return L10n.DAppRequest.ValidationOutcome.subtitleWrongNetworkID
		case .invalidOrigin, .invalidDappDefinitionAddress, .p2pError:
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
		case .wrongNetworkID:
			return shortExplanation
		case let .p2pError(message):
			return message
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
		case let .wrongNetworkID(ce, wallet):
			return L10n.DAppRequest.RequestWrongNetworkAlert.message(ce, wallet)
		case .p2pError:
			return L10n.DAppRequest.ValidationOutcome.shortExplanationP2PError
		}
	}
}

extension DappInteractor {
	func handleIncomingRequests() -> EffectTask<Action> {
		.run { send in
			for try await incomingRequest in dappInteractionClient.interactions {
				guard !Task.isCancelled else {
					return
				}

				switch incomingRequest {
				case let .valid(requestEnvelope):
					await send(.internal(.receivedRequestFromDapp(
						requestEnvelope
					)))
				case let .invalid(invalid):
					let isDeveloperModeEnabled = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled
					await send(.internal(.presentInvalidRequest(invalid, isDeveloperModeEnabled: isDeveloperModeEnabled)))
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
		.task {
			try await clock.sleep(for: delay)
			return action
		}
	}
}
