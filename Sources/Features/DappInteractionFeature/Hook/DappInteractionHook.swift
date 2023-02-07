import FeaturePrelude
import P2PConnectivityClient
import ProfileClient

// MARK: - DappInteractionHook
struct DappInteractionHook: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var requestQueue: OrderedSet<P2P.RequestFromClient> = []

		typealias DappInteractionState = RelayState<P2P.RequestFromClient, DappInteractionCoordinator.State>
		typealias DappInteractionAction = RelayAction<P2P.RequestFromClient, DappInteractionCoordinator.Action>

		@PresentationState
		var currentDappInteraction: DappInteractionState?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case receivedRequestFromDapp(P2P.RequestFromClient)
		case sentResponseToDapp(for: P2P.RequestFromClient)
	}

	enum ChildAction: Sendable, Equatable {
		case dappInteraction(PresentationAction<State.DappInteractionState, State.DappInteractionAction>)
	}

	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$currentDappInteraction, action: /Action.child .. ChildAction.dappInteraction) {
				Relay { DappInteractionCoordinator() }
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
			return presentInteractionIfNeededEffect(state: &state)

		case let .sentResponseToDapp(request):
			state.requestQueue.remove(request)
			state.currentDappInteraction = nil
			return .concatenate(
				.run { _ in try await clock.sleep(for: .seconds(1)) },
				presentInteractionIfNeededEffect(state: &state)
			)
		}
	}

	func presentInteractionIfNeededEffect(
		state: inout State
	) -> EffectTask<Action> {
		if
			state.currentDappInteraction == nil,
			let next = state.requestQueue.first
		{
			state.currentDappInteraction = .relayed(next, with: .init(interaction: next.interaction))
		}
		return .none
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .dappInteraction(.presented(.relay(request, .delegate(.dismiss)))):
			return .none
//			let response = P2P.ResponseToClientByID(
//				connectionID: request.client.id,
//				responseToDapp: response // TODO
//			)
//
//			return .run { [request] send in
//				do {
//					try await p2pConnectivityClient.sendMessage(response) // TODO: retry mechanism? :shrug:
//				} catch {
//					errorQueue.schedule(error)
//				}
//				await send(.internal(.sentResponseToDapp(for: request)))
//			}
		default:
			return .none
		}
	}
}
