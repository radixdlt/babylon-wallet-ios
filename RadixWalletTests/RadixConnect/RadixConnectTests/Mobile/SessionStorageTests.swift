import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class SessionStorageTests: XCTestCase {
	func test_session_storage_roundring() async throws {
		let sut = SecureSessionStorage()

		let id = UUID()
		let data = "some data".data(using: .utf8)!
		let returnData = "return data".data(using: .utf8)!
		let saveExpectation = XCTestExpectation(description: "Wait for save to be called")
		let loadExpectation = XCTestExpectation(description: "Wait for load to be called")

		try await withDependencies {
			$0.secureStorageClient.saveRadixConnectMobileSession = { savedId, savedData in
				XCTAssertEqual(savedId, id)
				XCTAssertEqual(savedData, data)

				saveExpectation.fulfill()
			}
			$0.secureStorageClient.loadRadixConnectMobileSession = { loadId in
				XCTAssertEqual(loadId, id)
				loadExpectation.fulfill()
				return returnData
			}
		} operation: {
			try await sut.saveSession(sessionId: id, encodedSession: data)
			let loadedData = try await sut.loadSession(sessionId: id)

			await fulfillment(of: [saveExpectation, loadExpectation], timeout: 1)
			XCTAssertEqual(loadedData, returnData)
		}
	}
}
