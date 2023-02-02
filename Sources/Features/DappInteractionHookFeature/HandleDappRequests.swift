import DappInteractionFeature
import FeaturePrelude
import P2PConnectivityClient
import ProfileClient
import TransactionClient
// import TransactionSigningFeature

// MARK: - HandleDappRequests
public struct HandleDappRequests: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
//		public var currentRequest: P2P.UnfinishedRequestFromClient?
		public var unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient

		public init(
			//			currentRequest: P2P.UnfinishedRequestFromClient? = nil,
			unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient = .init()
		) {
//			self.currentRequest = currentRequest
			self.unfinishedRequestsFromClient = unfinishedRequestsFromClient
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
	}

	public enum InternalAction: Sendable, Equatable {
		case loadClientIDsResult(TaskResult<OrderedSet<P2PClient.ID>>)
		case receivedRequestIsValidHandleIt(P2P.RequestFromClient)
		case sendMessageReceivedReceiptBackToPeer(P2PClient, readMessage: P2PConnections.IncomingMessage)
		case sendMessageReceivedReceiptBackToPeerResult(TaskResult<P2PConnections.IncomingMessage>)
		case receiveRequestFromP2PClientResult(TaskResult<P2P.RequestFromClient>)
		case rejected(P2P.RequestFromClient)
		case failedWithError(P2P.RequestFromClient, P2P.ToDapp.WalletInteractionFailureResponse.ErrorType, String?)
		case handleNextRequestItemIfNeeded
		case presentViewForP2PRequest(P2P.RequestItemToHandle)
		case sendResponseBackToDappResult(TaskResult<P2P.SentResponseToClient>)
	}

	public enum ChildAction: Sendable, Equatable {
//		case chooseAccounts(ChooseAccounts.Action)
//		case transactionSigning(TransactionSigning.Action)
	}

	@Dependency(\.profileClient) var profileClient
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
//			.ifLet(\.chooseAccounts, action: /Action.child .. ChildAction.chooseAccounts) {
//				ChooseAccounts()
//			}
//			.ifLet(\.transactionSigning, action: /Action.child .. ChildAction.transactionSigning) {
//				TransactionSigning()
//			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .internal(.receiveRequestFromP2PClientResult(.failure(error))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.sendMessageReceivedReceiptBackToPeer(client, readMessage)):
			return .run { send in
				await send(.internal(.sendMessageReceivedReceiptBackToPeerResult(
					TaskResult {
						try await p2pConnectivityClient.sendMessageReadReceipt(client.id, readMessage)
						return readMessage
					}
				)))
			}

		case .internal(.sendMessageReceivedReceiptBackToPeerResult(.success(_))):
			return .none

		case let .internal(.sendMessageReceivedReceiptBackToPeerResult(.failure(error))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.receiveRequestFromP2PClientResult(.success(requestFromP2P))):

			return .run { send in
				let currentNetworkID = await profileClient.getCurrentNetworkID()

				guard requestFromP2P.interaction.metadata.networkId == currentNetworkID else {
					let incommingRequestNetwork = try Network.lookupBy(id: requestFromP2P.interaction.metadata.networkId)
					let currentNetwork = try Network.lookupBy(id: currentNetworkID)

					await send(.internal(.failedWithError(
						requestFromP2P,
						.wrongNetwork,
						L10n.DApp.Request.wrongNetworkError(incommingRequestNetwork.name, currentNetwork.name)
					)))
					return
				}
				await send(.internal(.receivedRequestIsValidHandleIt(requestFromP2P)))
			}

		case let .internal(.receivedRequestIsValidHandleIt(validRequestFromP2P)):
			state.unfinishedRequestsFromClient.queue(requestFromClient: validRequestFromP2P)

//			guard state.currentRequest == nil else {
//				// already handling a requests
//				return .none
//			}
			guard let itemToHandle = state.unfinishedRequestsFromClient.next() else {
				// We just queued a request, did it contain no RequestItems at all? This is undefined behavior. Should we return an empty response here?
				return .none
			}
			return .run { send in
				await send(.internal(.presentViewForP2PRequest(itemToHandle)))
			}

		case let .internal(.presentViewForP2PRequest(requestItemToHandle)):
//			state.currentRequest = .init(requestItemToHandle: requestItemToHandle)
			return .none

//		case let .child(.chooseAccounts(.delegate(.finishedChoosingAccounts(selectedAccounts, request)))):
////			state.currentRequest = nil
//
//			let simpleInfoForAccounts: [P2P.ToDapp.WalletAccount] = selectedAccounts.map {
//				.init(account: $0)
//			}
//			guard !request.requestItem.requiresProofOfOwnership else {
//				errorQueue.schedule(NSError(domain: "UnsupportedDappRequest - proofs for account addresses is not yet supported", code: 0))
//				return .none
//			}
//			let responseItem = P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem.oneTimeAccounts(
//				.withoutProof(.init(accounts: .init(rawValue: simpleInfoForAccounts)!))
//			)
//
//			guard let responseToDapp = state.unfinishedRequestsFromClient.finish(
//				.oneTimeAccounts(request.requestItem), with: responseItem
//			) else {
//				return .run { send in
//					await send(.internal(.handleNextRequestItemIfNeeded))
//				}
//			}
//
//			let response = P2P.ResponseToClientByID(
//				connectionID: request.parentRequest.client.id,
//				responseToDapp: responseToDapp
//			)
//
//			return .run { [p2pConnectivityClient] send in
//				await send(.internal(.sendResponseBackToDappResult(
//					TaskResult {
//						try await p2pConnectivityClient.sendMessage(response)
//					}
//				)))
//			}

		case .internal(.handleNextRequestItemIfNeeded):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case .internal(.sendResponseBackToDappResult(.success(_))):
			return presentViewForNextBufferedRequestFromBrowserIfNeeded(state: &state)

		case let .internal(.sendResponseBackToDappResult(.failure(error))):
			errorQueue.schedule(error)
			return .none

//		case let .child(.transactionSigning(.delegate(.failed(failedRequest?, txFailure)))):
//			return .run { send in
//				let (errorKind, message) = txFailure.errorKindAndMessage
//				await send(.internal(
//					.failedWithError(
//						failedRequest.parentRequest,
//						errorKind,
//						message
//					)))
//			}

//		case let .child(.transactionSigning(.delegate(.signedTXAndSubmittedToGateway(txID, request?)))):
////			state.currentRequest = nil
//			let responseItem = P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem.send(
//				.init(txID: txID)
//			)
//			guard let responseToDapp = state.unfinishedRequestsFromClient.finish(.send(request.requestItem), with: responseItem) else {
//				return .run { send in
//					await send(.internal(.handleNextRequestItemIfNeeded))
//				}
//			}
//			let response = P2P.ResponseToClientByID(
//				connectionID: request.parentRequest.client.id,
//				responseToDapp: responseToDapp
//			)
//
//			return .run { send in
//				await send(.internal(.sendResponseBackToDappResult(
//					TaskResult {
//						try await p2pConnectivityClient.sendMessage(response)
//					}
//				)))
//			}

//		case let .child(.transactionSigning(.delegate(.rejected(rejectedRequestItem?)))):
//			return .run { send in
//				await send(.internal(.rejected(rejectedRequestItem.parentRequest)))
//			}
//
//		case let .child(.chooseAccounts(.delegate(.dismissChooseAccounts(rejectedRequestItem)))):
//			return .run { send in
//				await send(.internal(.rejected(rejectedRequestItem.parentRequest)))
//			}

		case let .internal(.rejected(request)):
			return respondBackWithFailure(
				state: &state,
				connectionID: request.client.id,
				failure: .init(
					interactionId: request.interaction.id,
					errorType: .rejectedByUser,
					message: nil
				)
			)

		case let .internal(.failedWithError(request, error, message)):
			errorQueue.schedule(error)
			return respondBackWithFailure(
				state: &state,
				connectionID: request.client.id,
				failure: .init(
					interactionId: request.interaction.id,
					errorType: error,
					message: message
				)
			)

		case .view(.task):
			return .run { send in
				do {
					try await p2pConnectivityClient.loadFromProfileAndConnectAll()
					for try await clientIDs in try await p2pConnectivityClient.getP2PClientIDs() {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.loadClientIDsResult(.success(clientIDs))))
					}
				} catch {
					await send(.internal(.loadClientIDsResult(.failure(error))))
				}
			}

		case let .internal(.loadClientIDsResult(.success(clientIDs))):
			return .run { send in
				for clientID in clientIDs {
					do {
						for try await request in try await p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence(clientID) {
							await send(.internal(.sendMessageReceivedReceiptBackToPeer(
								request.client, readMessage: request.originalMessage
							)))

							await send(.internal(.receiveRequestFromP2PClientResult(.success(request))))
						}
					} catch {
						await send(.internal(.receiveRequestFromP2PClientResult(.failure(error))))
					}
				}
			}

		case let .internal(.loadClientIDsResult(.failure(error))):
			errorQueue.schedule(error)
			return .none

		case .child:
			return .none
		}
	}

	func respondBackWithFailure(
		state: inout State,
		connectionID: P2PClient.ID,
		failure: P2P.ToDapp.WalletInteractionFailureResponse
	) -> EffectTask<Action> {
//		state.currentRequest = nil
		state.unfinishedRequestsFromClient.failed(interactionId: failure.interactionId)

		let response = P2P.ResponseToClientByID(
			connectionID: connectionID,
			responseToDapp: .failure(failure)
		)

		return .run { [p2pConnectivityClient] send in
			await send(.internal(.sendResponseBackToDappResult(
				TaskResult {
					try await p2pConnectivityClient.sendMessage(response)
				}
			)))
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
			await send(.internal(.presentViewForP2PRequest(next)))
		}
	}
}

// extension ApproveTransactionFailure {
//	var errorKindAndMessage: (errorKind: P2P.ToDapp.WalletInteractionFailureResponse.ErrorType, message: String?) {
//		switch self {
//		case let .transactionFailure(transactionFailure):
//			switch transactionFailure {
//			case let .failedToCompileOrSign(error):
//				switch error {
//				case .failedToCompileNotarizedTXIntent, .failedToCompileTXIntent, .failedToCompileSignedTXIntent, .failedToGenerateTXId:
//					return (errorKind: .failedToCompileTransaction, message: nil)
//				case .failedToSignIntentWithAccountSigners, .failedToSignSignedCompiledIntentWithNotarySigner, .failedToConvertNotarySignature, .failedToConvertAccountSignatures:
//					return (errorKind: .failedToSignTransaction, message: nil)
//				}
//			case let .failedToPrepareForTXSigning(error):
//				return (errorKind: .failedToPrepareTransaction, message: error.errorDescription)
//
//			case let .failedToSubmit(submissionError):
//
//				switch submissionError {
//				case .failedToSubmitTX:
//					return (errorKind: .failedToSubmitTransaction, message: nil)
//				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .rejected):
//					return (errorKind: .submittedTransactionHasRejectedTransactionStatus, message: "TXID: \(txID)")
//				case let .invalidTXWasSubmittedButNotSuccessful(txID, status: .failed):
//					return (errorKind: .submittedTransactionHasFailedTransactionStatus, message: "TXID: \(txID)")
//				case let .failedToPollTX(txID, _):
//					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
//				case let .invalidTXWasDuplicate(txID):
//					return (errorKind: .submittedTransactionWasDuplicate, message: "TXID: \(txID)")
//				case let .failedToGetTransactionStatus(txID, _):
//					return (errorKind: .failedToPollSubmittedTransaction, message: "TXID: \(txID)")
//				}
//			}
//
//		case let .prepareTransactionFailure(prepareTransactionFailure):
//			switch prepareTransactionFailure {
//			case let .addTransactionFee(addTransactionFeeError):
//				return (errorKind: .failedToPrepareTransaction, message: addTransactionFeeError.localizedDescription)
//			case let .loadNetworkID(loadNetworkIDError):
//				return (errorKind: .failedToPrepareTransaction, message: loadNetworkIDError.localizedDescription)
//			}
//		}
//	}
// }
