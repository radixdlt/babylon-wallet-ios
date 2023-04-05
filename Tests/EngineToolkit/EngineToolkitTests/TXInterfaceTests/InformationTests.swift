import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "4d4ca4d993539258e61fa9f9e8da9c209a91d823"
			)
		)
	}
}
