@testable import CacheClient
import ClientTestingPrelude

public func assertThrowsError<T>(
	_ function: () async throws -> T,
	_ message: @autoclosure () -> String = "",
	line: UInt = #line,
	file: StaticString = #filePath
) async throws {
	do {
		_ = try await function()
		XCTFail("Expected function to throw, but did not.\(message())", file: file, line: line)
	} catch {
		// All good, expected to throw
	}
}

public func assertNoThrowsError<T>(
	_ function: () async throws -> T,
	_ message: @autoclosure () -> String = "",
	line: UInt = #line,
	file: StaticString = #filePath
) async throws {
	do {
		_ = try await function()
		// All good, did not throw, as expected
	} catch {
		XCTFail("Got unexpected error: \(String(describing: error)).\(message())", file: file, line: line)
	}
}

// MARK: - CacheClientTests
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

		try await withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: 20, from: .now)
		} operation: {
			// when
			await sut.save(dataToBeSaved, entry)

			// then
			let retrived = try await sut.load(URL.self, entry)
			XCTAssertEqual(dataToBeSaved, retrived)

			// when
			await sut.removeFile(entry)
			// then
			try await assertThrowsError { try await sut.load(URL.self, entry) }
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
		try await withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: validTimeInterval, from: .now)
		} operation: {
			// when
			await sut.save(dataToBeSaved, entry)
			// then
			// then
			let retrived = try await sut.load(URL.self, entry)
			XCTAssertEqual(dataToBeSaved, retrived)
		}

		let boundaryTimeInterval: TimeInterval = 300
		try await withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: boundaryTimeInterval, from: .now)
		} operation: {
			// when
			await sut.save(dataToBeSaved, entry)
			// then
			// then
			let retrived = try await sut.load(URL.self, entry)
			XCTAssertEqual(dataToBeSaved, retrived)
		}

		let expiredTimeInterval: TimeInterval = 301
		try await withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .incrementing(by: expiredTimeInterval, from: .now)
		} operation: {
			// when
			await sut.save(dataToBeSaved, entry)
			// then
			try await assertThrowsError { try await sut.load(URL.self, entry) }
		}
	}

	func test_removeAll() async throws {
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

		try await withDependencies {
			$0.diskPersistenceClient = .liveValue
			$0.date = .constant(.now)
		} operation: {
			// when
			await sut.save(data1, entry1)
			await sut.save(data2, entry2)
			await sut.save(data3, entry3)
			await sut.removeAll()
			// then
			try await assertThrowsError({ try await sut.load(URL.self, entry1) }, "Loading URL worked, but expected failure.")
			try await assertThrowsError({ try await sut.load(Bool.self, entry2) }, "Loading Bool worked, but expected failure.")
			try await assertThrowsError({ try await sut.load(Int.self, entry3) }, "Loading Int worked, but expected failure.")
		}
	}
}
