@testable import Radix_Wallet_Dev
import Sargon
import XCTest

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

	func test_saveLoadAndRemoveData() throws {
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
}
