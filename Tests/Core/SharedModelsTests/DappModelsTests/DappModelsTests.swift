//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation
@testable import SharedModels
import TestUtils
import XCTest

final class ToDappResponseTests: TestCase {
	func test_encode_response() throws {
		let response = P2P.ToDapp.Response(
			id: "an_id", items: [
				.ongoingAccountAddresses(.init(
					accountAddresses: .init(
						rawValue: [.init(
							accountAddress: try! .init(address: "address"),
							label: "Label",
							appearanceID: .fromIndex(0)
						)]
					)!
				)),
			]
		)
		let encoder = JSONEncoder()
		let jsonData = try encoder.encode(response)
		let jsonString = try XCTUnwrap(jsonData.prettyPrintedJSONString)
		print(jsonString)
		XCTAssertTrue(jsonString.contains(P2P.FromDapp.Discriminator.ongoingAccountAddresses.rawValue))
	}

	func test_decode_request_from_dApp() throws {
		let json = """
		{
		    "payload":
		    [
		        {
		            "requestType": "ongoingAccountAddresses",
		            "proofOfOwnership": false
		        }
		    ],
		    "requestId": "791638de-cefa-43a8-9319-aa31c582fc7d",
		    "metadata":
		    {
		        "networkId": 34,
		        "dAppId": "radixdlt.dashboard.com",
		        "origin": "https://dashboard-pr-126.rdx-works-main.extratools.works"
		    }
		}
		""".data(using: .utf8)!

		let decoder = JSONDecoder()
		let request = try decoder.decode(P2P.FromDapp.Request.self, from: json)
		let expectedItem = P2P.FromDapp.OneTimeAccountAddressesRequest(
			numberOfAddresses: .oneOrMore
		)
		XCTAssertEqual(request.items, [.oneTimeAccountAddresses(expectedItem)])
		XCTAssertEqual(
			request.metadata,
			.init(
				networkId: .init(34),
				origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
				dAppId: "radixdlt.dashboard.com"
			)
		)
		XCTAssertEqual(request.id, "791638de-cefa-43a8-9319-aa31c582fc7d")
	}

	func test_decode_sign_tx_request() throws {
		let json = """
		{
		    "metadata":
		    {
		        "networkId": 34,
		        "dAppId": "radixdlt.dashboard.com",
		        "origin": "https://dashboard-pr-126.rdx-works-main.extratools.works"
		    },
		  "payload" : [
		    {
		      "version" : 1,
		      "transactionManifest" : "",
		      "requestType" : "sendTransaction"
		    }
		  ],
		  "requestId" : "ed987de8-fc30-40d0-81ea-e3eef117a2cc"
		}
		""".data(using: .utf8)!
		let decoder = JSONDecoder()
		let request = try decoder.decode(P2P.FromDapp.Request.self, from: json)
		XCTAssertEqual(request.items.first?.signTransaction?.version, 1)
		XCTAssertEqual(request.id, "ed987de8-fc30-40d0-81ea-e3eef117a2cc")
	}
}
