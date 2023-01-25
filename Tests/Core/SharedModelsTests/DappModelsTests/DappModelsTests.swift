@testable import SharedModels
import TestingPrelude

final class ToDappResponseTests: TestCase {
	func test_encode_response() throws {
		let sut = P2P.ToDapp.WalletInteractionResponse.success(.init(
			interactionId: "an_id",
			items: .request(
				.unauthorized(.init(
					oneTimeAccounts: .withoutProof(.init(
						accounts: .init(
							rawValue: [.init(
								accountAddress: try! .init(address: "address"),
								label: "Label",
								appearanceId: .fromIndex(0)
							)]
						)!
					))
				))
			)
		))
		try XCTAssertJSONEncoding(
			sut,
			[
				"discriminator": "success",
				"interactionId": "an_id",
				"items": [
					"discriminator": "unauthorizedRequest",
					"oneTimeAccounts": [
						"accounts": [
							[
								"address": "address",
								"appearanceId": 0,
								"label": "Label",
							],
						],
					],
				],
			]
		)
	}

	func test_decode_dApp_request_with_oneTimeAccountsRead_request_item() throws {
		let json: JSON = [
			"interactionId": "791638de-cefa-43a8-9319-aa31c582fc7d",
			"items": [
				"discriminator": "unauthorizedRequest",
				"oneTimeAccounts": [
					"numberOfAccounts": [
						"quantifier": "exactly",
						"quantity": 2,
					],
					"requiresProofOfOwnership": true,
				],
			],
			"metadata": [
				"networkId": 34,
				"origin": "radixdlt.dashboard.com",
				"dAppId": "https://dashboard-pr-126.rdx-works-main.extratools.works",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.FromDapp.WalletInteraction(
				id: "791638de-cefa-43a8-9319-aa31c582fc7d",
				items: .request(
					.unauthorized(.init(
						oneTimeAccounts: .init(
							numberOfAccounts: .exactly(2),
							requiresProofOfOwnership: true
						)
					))
				),
				metadata: .init(
					networkId: 34,
					origin: "radixdlt.dashboard.com",
					dAppId: "https://dashboard-pr-126.rdx-works-main.extratools.works"
				)
			)
		)
	}

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
}
