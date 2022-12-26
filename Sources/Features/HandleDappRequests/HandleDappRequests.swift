import Collections
import Common
import ComposableArchitecture
import Foundation
import GrantDappWalletAccessFeature
import P2PConnectivityClient
import Profile
import SharedModels
import TransactionClient
import TransactionSigningFeature

// MARK: - HandleDappRequests
public struct HandleDappRequests: Sendable, ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue

	public init() {}
}

public extension HandleDappRequests {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.chooseAccounts, action: /Action.child .. Action.ChildAction.chooseAccounts) {
				ChooseAccounts()
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

		case let .internal(.system(.sendMessageReceivedReceiptBackToPeer(client, readMessage))):
			return .run { send in
				await send(.internal(.system(.sendMessageReceivedReceiptBackToPeerResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessageReadReceipt(client.id, readMessage)
						return readMessage
					}
				))))
			}

		case .internal(.system(.sendMessageReceivedReceiptBackToPeerResult(.success(_)))):
			return .none

		case let .internal(.system(.sendMessageReceivedReceiptBackToPeerResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.receiveRequestFromP2PClientResult(.success(requestFromP2P)))):

			return .run { send in
				await send(.internal(.system(.sendMessageReceivedReceiptBackToPeer(requestFromP2P.client, readMessage: requestFromP2P.originalMessage))))

				let currentNetworkID = await profileClient.getCurrentNetworkID()

				guard requestFromP2P.requestFromDapp.metadata.networkId == currentNetworkID else {
					let incommingRequestNetwork = try Network.lookupBy(id: requestFromP2P.requestFromDapp.metadata.networkId)
					let currentNetwork = try Network.lookupBy(id: currentNetworkID)

					await send(.internal(.system(.failedWithError(
						requestFromP2P,
						.wrongNetwork,
						L10n.DApp.Request.wrongNetworkError(incommingRequestNetwork.name, currentNetwork.name)
					))))
					return
				}
				await send(.internal(.system(.receivedRequestIsValidHandleIt(requestFromP2P))))
			}

		case let .internal(.system(.receivedRequestIsValidHandleIt(validRequestFromP2P))):
			state.unfinishedRequestsFromClient.queue(requestFromClient: validRequestFromP2P)

			guard state.currentRequest == nil else {
				// already handling a requests
				return .none
			}
			guard let itemToHandle = state.unfinishedRequestsFromClient.next() else {
				// We just queued a request, did it contain no RequestItems at all? This is undefined behavior. Should we return an empty response here?
				return .none
			}
			return .run { send in
				await send(.internal(.system(.presentViewForP2PRequest(itemToHandle))))
			}

		case let .internal(.system(.presentViewForP2PRequest(requestItemToHandle))):
			state.currentRequest = .init(requestItemToHandle: requestItemToHandle)
			return .none

		case let .child(.chooseAccounts(.delegate(.finishedChoosingAccounts(selectedAccounts, request)))):
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

		case let .child(.transactionSigning(.delegate(.failed(failedRequest, txFailure)))):
			return .run { send in
				let (errorKind, message) = txFailure.errorKindAndMessage
				await send(.internal(.system(
					.failedWithError(
						failedRequest.parentRequest,
						errorKind,
						message
					))))
			}

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

		case let .child(.chooseAccounts(.delegate(.dismissChooseAccounts(rejectedRequestItem)))):
			return .run { send in
				await send(.internal(.system(.rejected(rejectedRequestItem.parentRequest))))
			}

		case let .internal(.system(.rejected(rejected))):
			return respondBackWithFailure(
				state: &state,
				connectionID: rejected.client.id,
				failure: .rejected(rejected.requestFromDapp)
			)

		case let .internal(.system(.failedWithError(request, error, message))):
			errorQueue.schedule(error)
			return respondBackWithFailure(
				state: &state,
				connectionID: request.client.id,
				failure: .request(request.requestFromDapp, failedWithError: error, message: message)
			)

		case .internal(.view(.task)):
			print("☑️ HandleDappRequests getting p2pClients...")
			return .run { send in
				print("☑️ HandleDappRequests getting p2pClients.......")
				do {
					for try await p2pClients in try await p2pConnectivityClient.getP2PConnections() {
						print("✅ HandleDappRequests got p2pClients: \(p2pClients.map(\.client.displayName)) ")
						await send(.internal(.system(.loadConnectionsResult(.success(p2pClients)))))
					}
				} catch {
					await send(.internal(.system(.loadConnectionsResult(.failure(error)))))
				}
			}

		case let .internal(.system(.loadConnectionsResult(.success(clients)))):
			print("☑️ HandleDappRequests getting requests for #\(clients.count) clients...")
			return .run { send in
				for connectedClient in clients {
					print("☑️ HandleDappRequests getting requests for client: '\(connectedClient.client.displayName)'.......")
					do {
						for try await request in try await p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence(connectedClient.client.id) {
							print("✅ HandleDappRequests got requests for client: '\(connectedClient.client.displayName)'!!!!")
							await send(.internal(.system(.receiveRequestFromP2PClientResult(.success(request)))))
						}
					} catch {
						await send(.internal(.system(.receiveRequestFromP2PClientResult(.failure(error)))))
					}
				}
			}

		case let .internal(.system(.loadConnectionsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .child:
			return .none
		}
	}

	func respondBackWithFailure(
		state: inout State,
		connectionID: P2PClient.ID,
		failure: P2P.ToDapp.Response.Failure
	) -> EffectTask<Action> {
		state.currentRequest = nil
		state.unfinishedRequestsFromClient.failed(requestID: failure.id)

		let response = P2P.ResponseToClientByID(
			connectionID: connectionID,
			responseToDapp: .failure(failure)
		)

		return .run { [p2pConnectivityClient] send in
			await send(.internal(.system(.sendResponseBackToDappResult(
				TaskResult {
					try await p2pConnectivityClient.sendMessage(response)
				}
			))))
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

extension ApproveTransactionFailure {
	var errorKindAndMessage: (errorKind: P2P.ToDapp.Response.Failure.Kind.Error, message: String?) {
		switch self {
		case let .transactionFailure(transactionFailure):
			switch transactionFailure {
			case let .failedToCompileOrSign(error):
				switch error {
				case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId:
					return (errorKind: .failedToCompileTransaction, message: nil)
				case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
					return (errorKind: .failedToSignTransaction, message: nil)
				}
			case let .failedToPrepareForTXSigning(error):
				return (errorKind: .failedToPrepareTransaction, message: error.errorDescription)

			case let .failedToSubmit(submissionError):

				switch submissionError {
				case .failedToSubmitTX:
					return (errorKind: .failedToSubmitTransaction, message: nil)
				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
					return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "TXID: \(txID)")
				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
					return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "TXID: \(txID)")
				case let .failedToPollTX(txID, _):
					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
				case let .invalidTXWasDuplicate(txID):
					return (errorKind: .submittedTransactionWasDuplicate, message: "TXID: \(txID)")
				case let .failedToGetTransactionStatus(txID, _):
					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
				}
			}

		case let .prepareTransactionFailure(prepareTransactionFailure):
			switch prepareTransactionFailure {
			case let .addTransactionFee(addTransactionFeeError):
				return (errorKind: .failedToPrepareTransaction, message: addTransactionFeeError.localizedDescription)
			case let .loadNetworkID(loadNetworkIDError):
				return (errorKind: .failedToPrepareTransaction, message: loadNetworkIDError.localizedDescription)
			}
		}
	}
}
