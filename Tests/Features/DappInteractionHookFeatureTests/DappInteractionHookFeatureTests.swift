// import FeatureTestingPrelude
// @testable import DappInteractionHookFeature
//
// @MainActor
// final class DappInteractionHookFeatureTests: TestCase {
//	func test__GIVEN__initialState__WHEN__receiveChooseAccountRequest__THEN__request_is_queued_and_immediately_handled() async throws {
//		let clientsWasLoaded = ActorIsolated<Bool>(false)
//
//		let incomingRequestsAsyncChannel = AsyncBufferedChannel<P2P.RequestFromClient>()
//		let request = P2P.RequestFromClient.previewValueOneTimeAccountAccess
//		let clientIDs = OrderedSet(arrayLiteral: request.client.id)
//
//		let store = TestStore(
//			initialState: HandleDappRequests.State(),
//			reducer: HandleDappRequests()
//		) {
//			$0.p2pConnectivityClient.loadFromProfileAndConnectAll = {
//				await clientsWasLoaded.setValue(true)
//			}
//			$0.p2pConnectivityClient.getP2PClientIDs = {
//				AsyncJustSequence(clientIDs).eraseToAnyAsyncSequence()
//			}
//			$0.p2pConnectivityClient.getRequestsFromP2PClientAsyncSequence = { _ in incomingRequestsAsyncChannel.eraseToAnyAsyncSequence() }
//			$0.profileClient.getCurrentNetworkID = { .simulator }
//			$0.p2pConnectivityClient.sendMessageReadReceipt = { _, _ in /* do nothing */ }
//		}
//
//		let task = await store.send(.view(.task))
//		await store.receive(.internal(.system(.loadClientIDsResult(.success(clientIDs)))))
//
//		incomingRequestsAsyncChannel.send(request)
//
//		await store.receive(.internal(.system(.sendMessageReceivedReceiptBackToPeer(.previewValue, readMessage: request.originalMessage))))
//
//		await store.receive(.internal(.system(.receiveRequestFromP2PClientResult(.success(request)))))
//		await store.receive(.internal(.system(.sendMessageReceivedReceiptBackToPeerResult(.success(request.originalMessage)))))
//
//		await store.receive(.internal(.system(.receivedRequestIsValidHandleIt(request)))) {
//			$0.unfinishedRequestsFromClient.queue(requestFromClient: request)
//			XCTAssertNotNil($0.unfinishedRequestsFromClient.next())
//		}
//
//		await store.receive(.internal(.system(.presentViewForP2PRequest(.init(requestItem: request.interaction.erasedItems.first!, parentRequest: request))))) {
//			$0.currentRequest = .chooseAccounts(
//				.init(
//					kind: .oneTime,
//					dappDefinitionAddress: try! .init(address: "account_deadbeef"),
//					dappMetadata: .init(name: "Dapp name", description: "A description"),
//					request: try XCTUnwrap(P2P.OneTimeAccountsRequestToHandle(request: request))
//				)
//			)
//		}
//		await clientsWasLoaded.withValue {
//			XCTAssertTrue($0)
//		}
//		await task.cancel()
//	}
//
//	func test__GIVEN__already_handling_a_request__WHEN__receiveRequest__THEN__new_request_is_queued() async throws {
//		let currentRequest: HandleDappRequests.State.CurrentRequest = .chooseAccounts(
//			.init(
//				kind: .oneTime,
//				dappDefinitionAddress: try! .init(address: "account_deadbeef"),
//				dappMetadata: .init(name: "Dapp name", description: "A description"),
//				request: try XCTUnwrap(P2P.OneTimeAccountsRequestToHandle(request: .previewValueOneTimeAccountAccess))
//			)
//		)
//
//		let store = TestStore(
//			initialState: HandleDappRequests.State(
//				unfinishedRequestsFromClient: .init(),
//				currentRequest: currentRequest
//			),
//			reducer: HandleDappRequests()
//		) {
//			$0.profileClient.getCurrentNetworkID = { .simulator }
//			$0.p2pConnectivityClient.sendMessageReadReceipt = { _, _ in /* do nothing */ }
//		}
//
//		let newRequest = P2P.RequestFromClient.previewValueSignTXRequest
//		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
//			.success(newRequest)
//		))))
//
//		await store.receive(.internal(.system(.receivedRequestIsValidHandleIt(newRequest)))) {
//			$0.unfinishedRequestsFromClient.queue(requestFromClient: newRequest)
//			XCTAssertEqual($0.currentRequest, currentRequest)
//		}
//	}
//
//	func test__GIVEN__on_network_nebunet__WHEN__received_request_specifying_another_network__THEN__we_respond_back_to_dapp_with_error() async throws {
//		let messageSentToDapp = ActorIsolated<P2P.ResponseToClientByID?>(nil)
//
//		let currentNetworkID = NetworkID.mardunet
//		let request = P2P.RequestFromClient(
//			originalMessage: .previewValue,
//			interaction: .init(
//				id: .previewValue0,
//				items: .request(
//					.unauthorized(.init(
//						oneTimeAccounts: .previewValue // FIXME: should be testValue
//					))
//				),
//				metadata: .init(
//					networkId: .nebunet,
//					origin: "",
//					dAppDefinitionAddress: try! .init(address: "account_deadbeef")
//				)
//			),
//			client: .previewValue
//		)
//
//		let error = P2P.ToDapp.WalletInteractionFailureResponse.ErrorType.wrongNetwork
//		let errorMsg = "Request received from dApp for network nebunet, but you are currently connected to mardunet."
//
//		let response = P2P.ToDapp.WalletInteractionFailureResponse(
//			interactionId: request.interaction.id,
//			errorType: error,
//			message: errorMsg
//		)
//
//		let store = TestStore(
//			initialState: HandleDappRequests.State(
//				unfinishedRequestsFromClient: .init()
//			),
//			reducer: HandleDappRequests()
//		) {
//			$0.profileClient.getCurrentNetworkID = { currentNetworkID }
//			$0.errorQueue.schedule = {
//				guard let error = $0 as? P2P.ToDapp.WalletInteractionFailureResponse.ErrorType else {
//					return XCTFail("wrong error type")
//				}
//				XCTAssertEqual(error, .wrongNetwork)
//			}
//
//			$0.p2pConnectivityClient.sendMessage = {
//				await messageSentToDapp.setValue($0)
//				return P2P.SentResponseToClient(
//					sentReceipt: .init(
//						messageSent: .init(data: .deadbeef32Bytes, messageID: .deadbeef32Bytes)
//					),
//					responseToDapp: $0.responseToDapp,
//					client: .previewValue
//				)
//			}
//		}
//		store.exhaustivity = .off
//
//		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
//			.success(request)
//		))))
//
//		await store.receive(.internal(.system(.failedWithError(request, error, errorMsg))))
//
//		await messageSentToDapp.withValue {
//			XCTAssertEqual($0?.responseToDapp, .failure(response))
//		}
//	}
// }
