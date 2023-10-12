import ClientTestingPrelude
@testable import GatewayAPI
import TestingPrelude

final class GatewayAPITests: TestCase {
	private func doTest(_ jsonName: String, expected: [AssetBehavior]) throws {
		try testFixture(bundle: .module, jsonName: jsonName) { (assignments: GatewayAPI.ComponentEntityRoleAssignments) in
			XCTAssertEqual(assignments.extractBehaviors(), expected)
		}
	}

	func test_behavior_extraction() throws {
		try doTest("behaviors1", expected: [.supplyFlexible, .removableByThirdParty, .informationChangeable])
		try doTest("behaviors2", expected: [.supplyIncreasable, .supplyDecreasableByAnyone, .informationChangeable])
	}
}
