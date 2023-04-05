@testable import CacheClient
import ClientTestingPrelude

final class CacheClientTests: TestCase {
	private var sut: CacheClient!

	override func setUp() {
		super.setUp()
		sut = CacheClient.liveValue
	}

	override func tearDownWithError() throws {
		sut = nil
		super.tearDown()
	}

	func test_saveLoadAndDeleteEntry() async throws {
		// given
		guard let dataToBeSaved = URL(string: "https://test.com") else {
			XCTFail("Could not create URL from string")
			return
		}
		let entry: CacheClient.Entry = .networkName(dataToBeSaved.absoluteString)

		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: 20, from: .now)
		} operation: {
			// when
			sut.save(dataToBeSaved, entry)

			// then
			guard let retrived = try sut.load(URL.self, entry) as? URL else {
				XCTFail("Expected to decode URL")
				return
			}
			XCTAssertEqual(dataToBeSaved, retrived)

			// when
			sut.removeFile(entry)
			// then
			XCTAssertThrowsError(try sut.load(URL.self, entry))
		}
	}

	func test_saveAndLoadExpiredEntry() async throws {
		// given
		guard let dataToBeSaved = URL(string: "https://test.com") else {
			XCTFail("Could not create URL from string")
			return
		}
		// entry lifefime is 300 seconds
		let entry: CacheClient.Entry = .networkName(dataToBeSaved.absoluteString)
		let timeInterval: TimeInterval = 301

		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: timeInterval, from: .now)
		} operation: {
			// when
			sut.save(dataToBeSaved, entry)
			// then
			XCTAssertThrowsError(try sut.load(URL.self, entry))
		}
	}

	func test_removeAll() throws {
		// given
		guard let data1 = URL(string: "https://test.com") else {
			XCTFail("Could not create URL from string")
			return
		}
		let entry1: CacheClient.Entry = .networkName(data1.absoluteString)

		let data2 = true
		let entry2: CacheClient.Entry = .rolaDappVerificationMetadata("deadbeef-metadata")

		let data3 = 123
		let entry3: CacheClient.Entry = .rolaWellKnownFileVerification("deadbeef-url")

		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .constant(.now)
		} operation: {
			// when
			sut.save(data1, entry1)
			sut.save(data2, entry2)
			sut.save(data3, entry3)
			sut.removeAll()

			// then
			XCTAssertThrowsError(try sut.load(URL.self, entry1))
			XCTAssertThrowsError(try sut.load(Bool.self, entry2))
			XCTAssertThrowsError(try sut.load(Int.self, entry3))
		}
	}
}
