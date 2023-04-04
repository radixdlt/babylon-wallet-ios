import ClientTestingPrelude
@testable import DiskPersistenceClient

final class DiskPersistenceClientTests: TestCase {
	private var sut: DiskPersistenceClient!

	override func setUp() {
		super.setUp()
		sut = DiskPersistenceClient.live()
	}

	override func tearDownWithError() throws {
		sut = nil
		super.tearDown()
	}

	func test_SaveLoadAndRemoveData() throws {
		// given
		let dataForSaving = 123
		let writeableTestPath = "writeableTestPath"

		// when
		try sut.save(dataForSaving, writeableTestPath)

		// then
		guard let retrivedData = try sut.load(Int.self, writeableTestPath) as? Int else {
			XCTFail("Expected to load Int")
			return
		}

		XCTAssertEqual(dataForSaving, retrivedData)

		// when
		try sut.remove(writeableTestPath)

		// then
		XCTAssertThrowsError(try sut.load(String.self, writeableTestPath))
	}

	func test_removeAllData() throws {
		// given
		let path1 = "path1"
		let path2 = "path2"
		let path3 = "path3"
		let path4 = "path4"

		// when
		try sut.save(123, path1)
		try sut.save(BigDecimal(fromString: "340282366920938463463374607431768211455.987654321"), path2)
		try sut.save("deadbeef", path3)
		try sut.save(Date(), path4)

		try sut.removeAll()

		XCTAssertThrowsError(try sut.load(Int.self, path1))
		XCTAssertThrowsError(try sut.load(BigDecimal.self, path2))
		XCTAssertThrowsError(try sut.load(String.self, path3))
		XCTAssertThrowsError(try sut.load(Date.self, path4))
	}
}
