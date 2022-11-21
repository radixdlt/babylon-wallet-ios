import Collections
import ComposableArchitecture
import Foundation
import GrantDappWalletAccessFeature
import P2PConnectivityClient
import Profile
import SharedModels
import TransactionSigningFeature

// MARK: - HandleDappRequests
public struct HandleDappRequests: ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue

	public init() {}
}

public extension HandleDappRequests {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.grantDappWalletAccess, action: /Action.child .. Action.ChildAction.grantDappWalletAccess) {
				DappConnectionRequest()
			}
			.ifLet(\.transactionSigning, action: /Action.child .. Action.ChildAction.transactionSigning) {
				TransactionSigning()
			}
	}
}

private extension HandleDappRequests {
	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
//        case let .internal(.system(.subscribeToRequestsFromP2PClientByID(ids))):

		case let .internal(.system(.receiveRequestFromP2PClientResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.receiveRequestFromP2PClientResult(.success(requestFromP2P)))):
			state.unfinishedRequestsFromClient.queue(requestFromClient: requestFromP2P)

			guard state.currentRequest == nil else {
				// already handling a requests
				return .none
			}
			guard let itemToHandle = state.unfinishedRequestsFromClient.next() else {
				fatalError("We just queued a request, did it contain no RequestItems at all? This is undefined behaviour. Should we return an empty response here?")
			}
			return .run { send in
				await send(.internal(.system(.presentViewForP2PRequest(itemToHandle))))
			}

//        case let .internal(.system(.connectionsLoadedResult(.failure(error)))):
//            errorQueue.schedule(error)
//            return .none
//
//        case let .internal(.system(.connectionsLoadedResult(.success(connections)))):
//            let ids = OrderedSet(connections.map(\.id))
//            return .run { send in
//                await send(.internal(.system(.subscribeToRequestsFromP2PClientByID(ids))))
//            }

		case let .internal(.system(.presentViewForP2PRequest(requestItemToHandle))):
			state.currentRequest = .init(requestItemToHandle: requestItemToHandle)
			return .none

		case let .child(.grantDappWalletAccess(.delegate(.dismiss(dismissedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.dismissed(dismissedRequestItem.parentRequest))))
			}

		case let .internal(.system(.dismissed(dismissedRequest))):
			state.currentRequest = nil
			state.unfinishedRequestsFromClient.dismiss(request: dismissedRequest)
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case let .child(.grantDappWalletAccess(.delegate(.finishedChoosingAccounts(selectedAccounts, request)))):
			state.currentRequest = nil
			let accountAddresses: [P2P.ToDapp.WalletAccount] = selectedAccounts.map {
				.init(account: $0)
			}
			let responseItem = P2P.ToDapp.WalletResponseItem.ongoingAccountAddresses(.init(accountAddresses: .init(rawValue: accountAddresses)!))

			guard let responseContent = state.unfinishedRequestsFromClient.finish(
				.oneTimeAccountAddresses(request.requestItem), with: responseItem
			) else {
				return .run { send in
					await send(.internal(.system(.handleNextRequestItemIfNeeded)))
				}
			}

			let response = P2P.ResponseToClientByID(
				connectionID: request.parentRequest.client.id,
				responseToDapp: responseContent
			)

			return .run { send in
				await send(.internal(.system(.sendResponseBackToDappResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessage(response)
					}
				))))
			}

		case .internal(.system(.handleNextRequestItemIfNeeded)):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case .internal(.system(.sendResponseBackToDappResult(.success(_)))):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case let .internal(.system(.sendResponseBackToDappResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child(.transactionSigning(.delegate(.signedTXAndSubmittedToGateway(_, _)))):
			state.currentRequest = nil

			// FIXME: Betanet: once we have migrated to Hammunet we can use the EngineToolkit to read out required signeres to sign tx.
			errorQueue.schedule(
				NSError(domain: "Transaction signing disabled until app is Hammunet compatible. Once we have it in place we should respond back with TXID to dApp here.", code: 1337)
			)
			return .none

		case let .child(.transactionSigning(.delegate(.dismissed(dismissedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.dismissed(dismissedRequestItem.parentRequest))))
			}
		case .internal(.view(.task)):
			return .run { send in
				await send(.internal(.system(.loadConnections)))
			}
		case .internal(.system(.loadConnections)):
			return .run { [p2pConnectivityClient] send in
				do {
					for try await updateList in try await p2pConnectivityClient.getP2PClients() {
						await withThrowingTaskGroup(of: Void.self) { taskGroup in
							for id in updateList.map(\.id) {
								taskGroup.addTask {
									do {
										let requests = try await p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence(id)
										for try await request in requests {
											await send(.internal(.system(.receiveRequestFromP2PClientResult(.success(request)))))
										}
									} catch {
										await send(.internal(.system(.receiveRequestFromP2PClientResult(.failure(error)))))
									}
								}
							}
						}
					}
				} catch {}
			}

		case .child:
			return .none
		}
	}

	func presentViewForNextBufferedRequestFromBrowserIfNeeded(state: inout State) -> EffectTask<Action> {
		guard let next = state.unfinishedRequestsFromClient.next() else {
			return .none
		}
		return .run { send in
			try await mainQueue.sleep(for: .seconds(1))
			await send(.internal(.system(.presentViewForP2PRequest(next))))
		}
	}

	//        func loadP2PClientConnections() -> EffectTask<Action> {
	//            .run { send in
	//                await send(.internal(.system(.connectionsLoadedResult(
	//                    TaskResult {
	//                        try await p2pConnectivityClient.getP2PClients()
	//                    }
	//                ))))
	//            }
	//        }
}
