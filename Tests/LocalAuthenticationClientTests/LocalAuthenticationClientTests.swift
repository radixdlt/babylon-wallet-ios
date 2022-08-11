//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-08-11.
//

import Foundation
@testable import LocalAuthenticationClient
import TestUtils

final class LocalAuthenticationClientTests: TestCase {
	let sut = LocalAuthenticationClient.live()

	func testTrivial() async throws {
		let config = try await sut.queryConfig()
		XCTAssertTrue(config.isPasscodeSetUp)
	}
}
