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

		let validTimeInterval: TimeInterval = 299
		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: validTimeInterval, from: .now)
		} operation: {
			// when
			sut.save(dataToBeSaved, entry)
			// then
			// then
			guard let retrived = try sut.load(URL.self, entry) as? URL else {
				XCTFail("Expected to decode URL")
				return
			}
			XCTAssertEqual(dataToBeSaved, retrived)
		}

		let boundaryTimeInterval: TimeInterval = 300
		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: boundaryTimeInterval, from: .now)
		} operation: {
			// when
			sut.save(dataToBeSaved, entry)
			// then
			// then
			guard let retrived = try sut.load(URL.self, entry) as? URL else {
				XCTFail("Expected to decode URL")
				return
			}
			XCTAssertEqual(dataToBeSaved, retrived)
		}

		let expiredTimeInterval: TimeInterval = 301
		try withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: expiredTimeInterval, from: .now)
		} operation: {
			// when
			sut.save(dataToBeSaved, entry)
			// then
			XCTAssertThrowsError(try sut.load(URL.self, entry))
		}
	}
}
