import TestUtils
@testable import UserDefaultsClient

// MARK: - UserDefaultsClientLiveTests
final class UserDefaultsClientLiveTests: TestCase {
	private var sut: UserDefaultsClient!

	override func setUp() {
		super.setUp()
		sut = UserDefaultsClient.liveValue
	}

	override func tearDown() {
		sut = nil
		super.tearDown()
	}

	func testBoolForKeyReturnsFalseForUnknownKey() {
		XCTAssertEqual(sut.boolForKey("unknownKey"), false)
	}

	func testDataForKeyReturnsNilForUnknownKey() {
		XCTAssertEqual(sut.dataForKey("unknownKey"), nil)
	}

	func testDoubleForKeyReturnsZeroForUnknownKey() {
		XCTAssertEqual(sut.doubleForKey("unknownKey"), 0)
	}

	func testIntegerForKeyReturnsZeroForUnknownKey() {
		XCTAssertEqual(sut.integerForKey("unknownKey"), 0)
	}

	func testSetBoolPersistsValue() async throws {
		await sut.setBool(true, "key")
		XCTAssertEqual(sut.boolForKey("key"), true)
	}

	func testSetDataPersistsValue() async throws {
		await sut.setData("deadbeef".hexData, "key")
		XCTAssertEqual(sut.dataForKey("key"), "deadbeef".hexData)
	}

	func testSetDoublePersistsValue() async throws {
		await sut.setDouble(3.14, "pi")
		XCTAssertEqual(sut.doubleForKey("pi"), 3.14)
	}

	func testSetIntegerPersistsValue() async throws {
		await sut.setInteger(1022, "key")
		XCTAssertEqual(sut.integerForKey("key"), 1022)
	}

	func testRemove() async throws {
		let key = "key"
		await sut.setData("deadbeef".hexData, key)
		XCTAssertEqual(sut.dataForKey(key), "deadbeef".hexData)
		await sut.remove(key)
		XCTAssertEqual(sut.dataForKey(key), nil, "Data should be nil since it was removed.")
	}
}
