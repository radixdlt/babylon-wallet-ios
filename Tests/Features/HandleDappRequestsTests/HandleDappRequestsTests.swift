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
		)

		let request = P2P.RequestFromClient.placeholderOneTimeAccountAccess

		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
			.success(request)
		)))) {
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
		)

		let newRequest = P2P.RequestFromClient.placeholderSignTXRequest

		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(
			.success(newRequest)
		)))) {
			$0.unfinishedRequestsFromClient.queue(requestFromClient: newRequest)
			XCTAssertEqual($0.currentRequest, currentRequest)
		}
	}

	func test__GIVEN__initialState__WHEN__finishing_first_item_of_two_in_a_request__THEN__next_item_is_started() async throws {
		let item0 = P2P.FromDapp.WalletRequestItem.oneTimeAccountAddresses(.placeholder)
		let item1 = P2P.FromDapp.WalletRequestItem.signTransaction(.placeholder)

		let request = try P2P.RequestFromClient(
			requestFromDapp: .init(
				id: .placeholder,
				metadata: .placeholder,
				items: [
					// GIVEN a request with two items
					item0,
					item1,
				]
			),
			client: .placeholder
		)

		let currentRequest: HandleDappRequests.State.CurrentRequest = try .grantDappWalletAccess(
			.init(request: request)
		)

		let store = TestStore(
			initialState: HandleDappRequests.State(
				unfinishedRequestsFromClient: .init(),
				currentRequest: nil
			),
			reducer: HandleDappRequests()
		)

		await store.send(.internal(.system(.receiveRequestFromP2PClientResult(.success(request))))) {
			$0.unfinishedRequestsFromClient.queue(requestFromClient: request)
			XCTAssertNotNil($0.unfinishedRequestsFromClient.next())
		}
		//        await store.receive(.internal(.system(.handleNextRequestItemIfNeeded)))
		await store.receive(.internal(.system(.presentViewForP2PRequest(.init(requestItem: item0, parentRequest: request))))) {
			$0.currentRequest = currentRequest
		}

		//        await store.send(.internal(.system(.handleNextRequestItemIfNeeded))) {
		//            $0.unfinishedRequestsFromClient.next()
		//        }

		let accountAddresses = NonEmpty<OrderedSet<OnNetwork.Account>>(rawValue: .init([.placeholder0]))!
		let accountAddressesResponse: NonEmpty<[P2P.ToDapp.WalletAccount]> = accountAddresses.map { P2P.ToDapp.WalletAccount(account: $0) }

		await store.send(.child(.grantDappWalletAccess(.delegate(
			.finishedChoosingAccounts(
				accountAddresses,
				request: .init(requestItem: item0.oneTimeAccountAddresses!, parentRequest: request)
			)
		)))) {
			XCTAssertNotNil($0.unfinishedRequestsFromClient.finish(item0, with: .oneTimeAccountAddresses(.withoutProof(.init(accountAddresses: accountAddressesResponse)))))
			$0.currentRequest = nil
		}
		await store.receive(.internal(.system(.handleNextRequestItemIfNeeded)))
	}
}
