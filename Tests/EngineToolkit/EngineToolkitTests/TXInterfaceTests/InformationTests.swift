import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.8.0",
				gitHash: "965ebfd7cf87de4e22e78d542b54ba27ab4db52a"
			)
		)
	}
}
