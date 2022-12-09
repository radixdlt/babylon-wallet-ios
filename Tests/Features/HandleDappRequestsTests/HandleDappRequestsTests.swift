import Collections
import ComposableArchitecture
import Foundation
@testable import HandleDappRequests
import NonEmpty
import Profile
import SharedModels
import TestUtils
import XCTest

@MainActor
final class HandleDappRequestsTests: TestCase {
	func test__GIVEN__initialState__WHEN__receiveChooseAccountRequest__THEN__request_is_queued_and_immediately_handled() async throws {
		let store = TestStore(
			initialState: HandleDappRequests.State(),
			reducer: HandleDappRequests()
		) {
			$0.profileClient.getCurrentNetworkID = { .simulator }
		}

		let request = P2P.RequestFromClient.placeholderOneTimeAccountAccess

		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
			.success(request)
		))))

		await store.receive(.internal(.system(.receivedRequestIsValidHandleIt(request)))) {
			$0.unfinishedRequestsFromClient.queue(requestFromClient: request)
			XCTAssertNotNil($0.unfinishedRequestsFromClient.next())
		}

		await store.receive(.internal(.system(.presentViewForP2PRequest(.init(requestItem: request.requestFromDapp.items.first!, parentRequest: request))))) {
			try $0.currentRequest = .chooseAccounts(
				.init(request: request)
			)
		}
	}

	func test__GIVEN__already_handling_a_request__WHEN__receiveRequest__THEN__new_request_is_queued() async throws {
		let request = P2P.RequestFromClient.placeholderOneTimeAccountAccess

		let currentRequest: HandleDappRequests.State.CurrentRequest = try .chooseAccounts(
			.init(request: request)
		)

		let store = TestStore(
			initialState: HandleDappRequests.State(
				unfinishedRequestsFromClient: .init(),
				currentRequest: currentRequest
			),
			reducer: HandleDappRequests()
		) {
			$0.profileClient.getCurrentNetworkID = { .simulator }
		}

		let newRequest = P2P.RequestFromClient.placeholderSignTXRequest
		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
			.success(newRequest)
		))))
		await store.receive(.internal(.system(.receivedRequestIsValidHandleIt(newRequest)))) {
			$0.unfinishedRequestsFromClient.queue(requestFromClient: newRequest)
			XCTAssertEqual($0.currentRequest, currentRequest)
		}
	}

	func test__GIVEN__on_network_nebunet__WHEN__received_request_specifying_another_network__THEN__we_respond_back_to_dapp_with_error() async throws {
		let messageSentToDapp = ActorIsolated<P2P.ResponseToClientByID?>(nil)
		let currentNetworkID = NetworkID.mardunet
		let request = try P2P.RequestFromClient(
			requestFromDapp: .init(
				id: .placeholder0,
				metadata: .init(
					networkId: .nebunet,
					origin: "",
					dAppId: ""
				), items: [
					.oneTimeAccounts(.placeholder),
				]
			),
			client: .placeholder
		)

		let error = P2P.ToDapp.Response.Failure.Kind.Error.wrongNetwork
		let errorMsg = "Wallet is using network ID: \(currentNetworkID), request sent specified network ID: \(request.requestFromDapp.metadata.networkId)."
		let response = P2P.ToDapp.Response.failure(.init(id: request.id, kind: .error(error), message: errorMsg))
		let store = TestStore(
			initialState: HandleDappRequests.State(
				unfinishedRequestsFromClient: .init()
			),
			reducer: HandleDappRequests()
		) {
			$0.profileClient.getCurrentNetworkID = { currentNetworkID }
			$0.errorQueue.schedule = {
				guard let error = $0 as? P2P.ToDapp.Response.Failure.Kind.Error else {
					return XCTFail("wrong error type")
				}
				XCTAssertEqual(error, .wrongNetwork)
			}
			$0.p2pConnectivityClient.sendMessage = {
				await messageSentToDapp.setValue($0)
				return .init(sentReceipt: .init(data: .deadbeef32Bytes, messageID: .deadbeef32Bytes), responseToDapp: $0.responseToDapp, client: .placeholder)
			}
		}
		store.exhaustivity = .off

		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
			.success(request)
		))))

		await store.receive(.internal(.system(.failedWithError(request, error, errorMsg))))

		await messageSentToDapp.withValue {
			XCTAssertEqual($0?.responseToDapp, response)
		}
	}
}
