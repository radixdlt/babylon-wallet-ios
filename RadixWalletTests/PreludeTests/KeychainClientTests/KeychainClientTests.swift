import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class KeychainClientTests: TestCase {
	/// Must NEVER fail, else user will have lost secrets!
	func test_keychain_client_live_service_is___Radix_Wallet() {
		let expectedService: String
		#if DEBUG
		expectedService = "Radix Wallet DEBUG"
		#else
		expectedService = "Radix Wallet"
		#endif
		guard KeychainClient.liveValue._getServiceAndAccessGroup().service == expectedService else {
			fatalError("This test is NEVER allowed to fail")
		}
	}
}
