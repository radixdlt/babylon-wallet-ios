import Collections
import ComposableArchitecture
import Foundation
import GrantDappWalletAccessFeature
import P2PConnectivityClient
import Profile
import SharedModels
import TransactionSigningFeature

// MARK: - HandleDappRequests
public struct HandleDappRequests: Sendable, ReducerProtocol {
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
				// We just queued a request, did it contain no RequestItems at all? This is undefined behaviour. Should we return an empty response here?
				return .none
			}
			return .run { send in
				await send(.internal(.system(.presentViewForP2PRequest(itemToHandle))))
			}

		case let .internal(.system(.presentViewForP2PRequest(requestItemToHandle))):
			state.currentRequest = .init(requestItemToHandle: requestItemToHandle)
			return .none

		case let .child(.grantDappWalletAccess(.delegate(.rejected(rejectedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.rejected(rejectedRequestItem.parentRequest))))
			}

		case let .internal(.system(.rejected(rejectedRequest))):
			state.currentRequest = nil
			let responseToDapp = state.unfinishedRequestsFromClient.rejected(request: rejectedRequest)

			let response = P2P.ResponseToClientByID(
				connectionID: rejectedRequest.client.id,
				responseToDapp: responseToDapp
			)

			return .run { [p2pConnectivityClient] send in
				await send(.internal(.system(.sendResponseBackToDappResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessage(response)
					}
				))))
			}

		case let .child(.grantDappWalletAccess(.delegate(.finishedChoosingAccounts(selectedAccounts, request)))):
			state.currentRequest = nil

			let simpleInfoForAccounts: [P2P.ToDapp.WalletAccount] = selectedAccounts.map {
				.init(account: $0)
			}
			guard !request.requestItem.isRequiringOwnershipProof else {
				errorQueue.schedule(NSError(domain: "UnsupportedDappRequest - proofs for account addresses is not yet supported", code: 0))
				return .none
			}
			let responseItem = P2P.ToDapp.WalletResponseItem.oneTimeAccounts(
				.withoutProof(.init(accounts: .init(rawValue: simpleInfoForAccounts)!))
			)

			guard let responseToDapp = state.unfinishedRequestsFromClient.finish(
				.oneTimeAccounts(request.requestItem), with: responseItem
			) else {
				return .run { send in
					await send(.internal(.system(.handleNextRequestItemIfNeeded)))
				}
			}

			let response = P2P.ResponseToClientByID(
				connectionID: request.parentRequest.client.id,
				responseToDapp: responseToDapp
			)

			return .run { [p2pConnectivityClient] send in
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

		case let .child(.transactionSigning(.delegate(.signedTXAndSubmittedToGateway(txID, request)))):
			state.currentRequest = nil
			let responseItem = P2P.ToDapp.WalletResponseItem.sendTransaction(
				.init(txID: txID)
			)
			guard let responseToDapp = state.unfinishedRequestsFromClient.finish(.sendTransaction(request.requestItem), with: responseItem) else {
				return .run { send in
					await send(.internal(.system(.handleNextRequestItemIfNeeded)))
				}
			}
			let response = P2P.ResponseToClientByID(
				connectionID: request.parentRequest.client.id,
				responseToDapp: responseToDapp
			)

			return .run { send in
				await send(.internal(.system(.sendResponseBackToDappResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessage(response)
					}
				))))
			}

		case let .child(.transactionSigning(.delegate(.rejected(rejectedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.rejected(rejectedRequestItem.parentRequest))))
			}
		case .internal(.view(.task)):
			return .run { send in
				await send(.internal(.system(.loadConnections)))
			}
		case .internal(.system(.loadConnections)):
			return .run { send in
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

	func presentViewForNextBufferedRequestFromBrowserIfNeeded(
		state: inout State
	) -> EffectTask<Action> {
		guard let next = state.unfinishedRequestsFromClient.next() else {
			return .none
		}

		return .run { send in
			try await mainQueue.sleep(for: .seconds(1))
			await send(.internal(.system(.presentViewForP2PRequest(next))))
		}
	}
}
