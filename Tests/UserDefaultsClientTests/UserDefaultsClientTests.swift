//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-06-30.
//

import Combine
import TestUtils

@testable import UserDefaultsClient

// MARK: - UserDefaultsClientLiveTests
final class UserDefaultsClientLiveTests: TestCase {
	private var sut: UserDefaultsClient!

	override func setUp() {
		super.setUp()
		sut = UserDefaultsClient.live(userDefaults: .init())
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
		try await completion(of: sut.setBool(true, "key"))
		XCTAssertEqual(sut.boolForKey("key"), true)
	}

	func testSetDataPersistsValue() async throws {
		try await completion(of: sut.setData("deadbeef".hexData, "key"))
		XCTAssertEqual(sut.dataForKey("key"), "deadbeef".hexData)
	}

	func testSetDoublePersistsValue() async throws {
		try await completion(of: sut.setDouble(3.14, "pi"))
		XCTAssertEqual(sut.doubleForKey("pi"), 3.14)
	}

	func testSetIntegerPersistsValue() async throws {
		try await completion(of: sut.setInteger(1022, "key"))
		XCTAssertEqual(sut.integerForKey("key"), 1022)
	}
	
	func testRemove() async throws {
		let key = "key"
		try await completion(of: sut.setData("deadbeef".hexData, key))
		XCTAssertEqual(sut.dataForKey(key), "deadbeef".hexData)
		try await completion(of: sut.remove(key))
		XCTAssertEqual(sut.dataForKey(key), nil, "Data should be nil since it was removed.")
	}
}
