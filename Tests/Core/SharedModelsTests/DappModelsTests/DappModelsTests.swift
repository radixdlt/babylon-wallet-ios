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

	func test_bas64() throws {
		let string = "eyJwYXlsb2FkIjpbeyJyZXF1ZXN0VHlwZSI6Im9uZ29pbmdBY2NvdW50QWRkcmVzc2VzIiwiYWNjb3VudEFkZHJlc3NlcyI6W3siYWRkcmVzcyI6ImFjY291bnRfdGR4X2FfMXF3dThxZGgwNGpzbHA5YWp0bmxuNng5dHNmM252eGQyaGc1ZXNrdjBlaDJzZXA4Z2ZjIiwibGFiZWwiOiJDeW9uIiwiYXBwZWFyYW5jZUlEIjowfV19XSwicmVxdWVzdElkIjoiMDRhOTcyNjEtNTQxMS00ZDI2LTg0MTAtY2FhZTA1NzU2Mjk2In0=".data(using: .utf8)!
	}
}
