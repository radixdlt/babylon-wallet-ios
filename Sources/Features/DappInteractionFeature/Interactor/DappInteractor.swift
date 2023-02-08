import FeaturePrelude
import P2PConnectivityClient
import ProfileClient

// MARK: - DappInteractionHook
struct DappInteractor: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RequestFromClient> = []

		@PresentationState
		var currentModal: Destinations.State?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RequestFromClient)
		case presentQueuedRequestIfNeeded
		case sentResponseToDapp(P2P.ToDapp.WalletInteractionResponse, for: P2P.RequestFromClient, DappMetadata?)
		case presentInteractionSuccessView(DappMetadata)
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
								return
							}

							await send(.internal(.receivedRequestFromDapp(request)))
						}
					}
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
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
			state.requestQueue.remove(request)
			state.currentModal = nil
			onDismiss?()
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				switch response {
				case .success:
					await send(.internal(.presentInteractionSuccessView(dappMetadata ?? DappMetadata(name: nil))))
				case .failure:
					await send(.internal(.presentQueuedRequestIfNeeded))
				}
			}

		case let .presentInteractionSuccessView(dappMetadata):
			state.currentModal = .dappInteractionCompletion(.init(dappMetadata: dappMetadata))
			return .none
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
		}
		return .none
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modal(.presented(.dappInteraction(.relay(request, .delegate(.submitAndDismiss(responseToDapp, dappMetadata)))))):
			let response = P2P.ResponseToClientByID(
				connectionID: request.client.id,
				responseToDapp: responseToDapp
			)

			return .run { send in
				do {
					_ = try await p2pConnectivityClient.sendMessage(response) // TODO: retry mechanism? :shrug:
				} catch {
					errorQueue.schedule(error)
				}
				await send(.internal(.sentResponseToDapp(responseToDapp, for: request, dappMetadata)))
			}

		case .modal(.presented(.dappInteractionCompletion(.delegate(.dismiss)))):
			state.currentModal = nil
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.presentQueuedRequestIfNeeded))
			}

		// NB: handles background tap to dismiss success screen.
		case .modal(.dismiss):
			switch state.currentModal {
			case .none, .dappInteraction:
				return .none
			case .dappInteractionCompletion:
				return .run { send in
					try await clock.sleep(for: .seconds(0.5))
					await send(.internal(.presentQueuedRequestIfNeeded))
				}
			}

		default:
			return .none
		}
	}
}
