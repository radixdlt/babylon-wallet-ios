import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.8.0",
				gitHash: "335fdc5547ba86f8d0fc2a1a35dd9e84409c78a0"
			)
		)
	}
}
