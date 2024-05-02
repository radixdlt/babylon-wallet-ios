// import Foundation
// @testable import Radix_Wallet_Dev
// import XCTest
import Sargon

//
//// MARK: - UserDefaultsClientLiveTests
// final class UserDefaultsClientLiveTests: TestCase {
//	private var sut: UserDefaultsClient!
//
//	override func setUp() {
//		super.setUp()
//		sut = UserDefaultsClient.liveValue
//	}
//
//	override func tearDown() {
//		sut = nil
//		super.tearDown()
//	}
//
//	func testActiveProfileIDKeyIsUnchanged() {
//		XCTAssertEqual(UserDefaultsClient.Key.activeProfileID.rawValue, "activeProfileID")
//	}
//
//	func testSetBoolPersistsValue() async throws {
//		await sut.setBool(true, .someKey)
//		XCTAssertEqual(sut.boolForKey(.someKey), true)
//	}
//
//	func testSetDataPersistsValue() async throws {
//		await sut.setData("deadbeef".hexData, .someKey)
//		XCTAssertEqual(sut.dataForKey(.someKey), "deadbeef".hexData)
//	}
//
//	func testSetDoublePersistsValue() async throws {
//		await sut.setDouble(3.14, .someKey)
//		XCTAssertEqual(sut.doubleForKey(.someKey), 3.14)
//	}
//
//	func testSetIntegerPersistsValue() async throws {
//		await sut.setInteger(1022, .someKey)
//		XCTAssertEqual(sut.integerForKey(.someKey), 1022)
//	}
//
//	func testRemove() async throws {
//		let key = UserDefaultsClient.Key.someKey
//		await sut.setData("deadbeef".hexData, key)
//		XCTAssertEqual(sut.dataForKey(key), "deadbeef".hexData)
//		await sut.remove(key)
//		XCTAssertEqual(sut.dataForKey(key), nil, "Data should be nil since it was removed.")
//	}
// }
//
// extension UserDefaultsClient.Key {
//	fileprivate static let someKey = Self.hideMigrateOlympiaButton
// }
