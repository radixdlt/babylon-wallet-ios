import Prelude

final class InformationTests: TestCase {
    func test__information() throws {
        let information = try sut.information().get()
        XCTAssertNoDifference(
            information,
            .init(
                packageVersion: "0.9.0",
                lastCommitHash: "4a47287fee8938edea8adf5c3fb43c5ff7d1a9bb"
            )
        )
    }
}
