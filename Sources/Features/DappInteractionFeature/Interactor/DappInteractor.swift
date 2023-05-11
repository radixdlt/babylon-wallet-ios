import AppPreferencesClient
import FeaturePrelude
import GatewaysClient
import RadixConnect
import RadixConnectClient
import ROLAClient

// MARK: - DappInteractor
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RTCIncomingDappRequest> = []

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
			case cancelButtonTapped(P2P.RTCIncomingDappRequest)
			case retryButtonTapped(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?)
		}

		enum InvalidRequestAlertAction: Sendable, Hashable {
			case ok(P2P.RTCIncomingDappRequest)
		}
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RTCIncomingDappRequest)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?)
		case failedToSendResponseToDapp(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?, reason: String)
		case presentResponseFailureAlert(P2P.Dapp.Response, for: P2P.RTCIncomingDappRequest, DappMetadata?, reason: String)
		case presentResponseSuccessView(DappMetadata)
		case presentInvalidRequest(for: P2P.RTCIncomingDappRequest, reason: DappRequestValidationOutcome.Invalid)
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
				state.invalidRequestAlert = nil // needed?
				return .none
			case let .presented(.ok(request)):
				state.invalidRequestAlert = nil // needed?
				dismissCurrentModalAndRequest(request, for: &state)
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

		case let .sentResponseToDapp(response, for: request, dappMetadata):
			dismissCurrentModalAndRequest(request, for: &state)
			switch response {
			case .success:
				// FIXME: cleanup DappMetaData
				return .send(.internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil, origin: .init("")))))
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

		case let .presentInvalidRequest(request, invalidReason):
			state.invalidRequestAlert = .init(
				title: { TextState("Invalid request") },
				actions: {
					ButtonState(role: .cancel, action: .ok(request)) {
						TextState(L10n.DApp.Response.FailureAlert.cancelButtonTitle)
					}
				},
				message: {
					TextState(invalidReason.subtitle)
					TextState(invalidReason.explaination)
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
			// FIXME: cleanup DappMetaData
			return .send(.internal(.presentResponseSuccessView(dappMetadata ?? DappMetadata(name: nil, origin: .init("")))))
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
		state.requestQueue.removeAll(where: { $0. })
		state.currentModal = nil
	}
}

// MARK: - DappRequestValidationOutcome
enum DappRequestValidationOutcome: Sendable, Hashable {
	case valid(P2P.Dapp.Request)
	case invalid(Invalid)
	enum Invalid: Sendable, Hashable {
		case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
		case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
		case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
		case rolaCheckFailed
		case badContent(BadContent)
		enum BadContent: Sendable, Hashable {
			case numberOfAccountsInvalid
		}
	}
}

extension DappRequestValidationOutcome.Invalid {
	var subtitle: String { "" }
	var explaination: String { "" }
}

extension DappInteractor {
	func validate(_ nonValidated: P2P.Dapp.RequestNonValidated) async -> DappRequestValidationOutcome {
		let nonvalidatedMeta = nonValidated.metadata
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

		let metadataValidDappDefAddres = P2P.Dapp.Request.Metadata(
			version: nonvalidatedMeta.version,
			networkId: nonvalidatedMeta.networkId,
			origin: nonvalidatedMeta.origin,
			dAppDefinitionAddress: dappDefinitionAddress
		)

		let performROLACheck = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled == false
		if performROLACheck {
			do {
				try await rolaClient.performDappDefinitionVerification(metadataValidDappDefAddres)
				try await rolaClient.performWellKnownFileCheck(metadataValidDappDefAddres)
			} catch {
				return .invalid(.rolaCheckFailed)
			}
		}

		return .valid(.init(
			id: nonValidated.id,
			items: nonValidated.items,
			metadata: metadataValidDappDefAddres
		)
		)
	}

	func handleIncomingRequests() -> EffectTask<Action> {
		.run { _ in
			_ = await radixConnectClient.loadFromProfileAndConnectAll()

			for try await incomingRequest in await radixConnectClient.receiveRequests(/P2P.RTCMessageFromPeer.Request.dapp) {
				guard !Task.isCancelled else {
					return
				}

				do {
					let requestToValidate = try incomingRequest.result.get()
					let validation = await validate(requestToValidate)
					//                    switch validation {
					//                    case let .valid(valid):
					//                        await send(.internal(.receivedRequestFromDapp(.init(
					//                            result: .success(valid),
					//                            route: incomingRequest.route
					//                        ))))
					//                    case let .invalid(reason):
					//                        await send(.internal(.presentInvalidRequest(for: .init(result: <#T##Result<P2P.Dapp.Request, Error>#>, route: <#T##P2P.RTCRoute#>), reason: reason)
					//                    }
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
