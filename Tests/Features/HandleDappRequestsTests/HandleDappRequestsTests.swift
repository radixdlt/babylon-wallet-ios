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
	func test__GIVEN__initialState__WHEN__receiveRequest__THEN__request_is_queued_and_immediately_handled() async throws {
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
			try $0.currentRequest = .grantDappWalletAccess(
				.init(request: request)
			)
		}
	}

	func test__GIVEN__already_handling_a_request__WHEN__receiveRequest__THEN__new_request_is_queued() async throws {
		let request = P2P.RequestFromClient.placeholderOneTimeAccountAccess

		let currentRequest: HandleDappRequests.State.CurrentRequest = try .grantDappWalletAccess(
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
}
