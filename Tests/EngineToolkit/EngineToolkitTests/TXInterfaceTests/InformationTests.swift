import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "675430693498d5910e666121673b89b0cce411d0"
			)
		)
	}
}
