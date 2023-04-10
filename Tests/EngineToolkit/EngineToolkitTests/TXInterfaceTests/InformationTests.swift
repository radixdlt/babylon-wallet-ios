import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "c6bc6bdbc3d5d1e60a0ad45e3a0f579c952d04cf"
			)
		)
	}
}
