// @testable import SharedModels
// import TestingPrelude
//
// final class ToDappResponseTests: TestCase {
//	func test_encode_response() throws {
//		let success = P2P.ToDapp.Response.Success(
//			id: "an_id", items: [
//				.oneTimeAccounts(.withoutProof(.init(
//					accounts: .init(
//						rawValue: [.init(
//							accountAddress: try! .init(address: "address"),
//							label: "Label",
//							appearanceId: .fromIndex(0)
//						)]
//					)!
//				))),
//			]
//		)
//		let response = P2P.ToDapp.Response.success(success)
//		let encoder = JSONEncoder()
//		let jsonData = try encoder.encode(response)
//		let jsonString = try XCTUnwrap(jsonData.prettyPrintedJSONString)
//		XCTAssertTrue(jsonString.contains(P2P.FromDapp.Discriminator.oneTimeAccountsRead.rawValue))
//	}
//
//	func test_decode_dApp_request_with_oneTimeAccountsRead_request_item() throws {
//		let json = """
//		{
//		    "items":
//		    [
//		        {
//		            "requestType": "oneTimeAccountsRead",
//		            "requiresProofOfOwnership": false
//		        }
//		    ],
//		    "requestId": "791638de-cefa-43a8-9319-aa31c582fc7d",
//		    "metadata":
//		    {
//		        "networkId": 34,
//		        "dAppId": "radixdlt.dashboard.com",
//		        "origin": "https://dashboard-pr-126.rdx-works-main.extratools.works"
//		    }
//		}
//		""".data(using: .utf8)!
//
//		let decoder = JSONDecoder()
//		let request = try decoder.decode(P2P.FromDapp.Request.self, from: json)
//		let expectedItem = P2P.FromDapp.OneTimeAccountsReadRequestItem(
//			numberOfAddresses: .oneOrMore
//		)
//		XCTAssertEqual(request.items, [.oneTimeAccounts(expectedItem)])
//		XCTAssertEqual(
//			request.metadata,
//			.init(
//				networkId: .init(34),
//				origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
//				dAppId: "radixdlt.dashboard.com"
//			)
//		)
//		XCTAssertEqual(request.id, "791638de-cefa-43a8-9319-aa31c582fc7d")
//	}
//
//	func test_decode_dApp_request_with_sendTransactionWrite_request_item() throws {
//		let json = """
//		{
//		    "metadata":
//		    {
//		        "networkId": 34,
//		        "dAppId": "radixdlt.dashboard.com",
//		        "origin": "https://dashboard-pr-126.rdx-works-main.extratools.works"
//		    },
//		  "items" : [
//		    {
//		      "version" : 1,
//		      "transactionManifest" : "",
//		      "requestType" : "sendTransactionWrite"
//		    }
//		  ],
//		  "requestId" : "ed987de8-fc30-40d0-81ea-e3eef117a2cc"
//		}
//		""".data(using: .utf8)!
//		let decoder = JSONDecoder()
//		let request = try decoder.decode(P2P.FromDapp.Request.self, from: json)
//		XCTAssertEqual(request.items.first?.sendTransaction?.version, 1)
//		XCTAssertEqual(request.id, "ed987de8-fc30-40d0-81ea-e3eef117a2cc")
//	}
// }
