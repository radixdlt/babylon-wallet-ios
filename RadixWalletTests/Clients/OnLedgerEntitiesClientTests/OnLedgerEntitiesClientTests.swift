@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class OnLedgerEntitiesClientTests: TestCase {
	private func doTest(_ jsonName: String, expected: [AssetBehavior]) throws {
		try testFixture(
			bundle: Bundle(for: Self.self),
			jsonName: jsonName
		) { (assignments: GatewayAPI.ComponentEntityRoleAssignments) in
			XCTAssertEqual(assignments.extractBehaviors(), expected)
		}
	}

	func test_behavior_extraction() throws {
		try doTest("behaviors1", expected: [.supplyFlexible, .removableByThirdParty, .informationChangeable])
		try doTest("behaviors2", expected: [.supplyIncreasable, .supplyDecreasableByAnyone, .informationChangeable])
	}
}
