import Foundation
@testable import Radix_Wallet_Dev

extension NSError {
	public static func testValue(domain: String = "Test") -> NSError {
		NSError(domain: domain, code: 1)
	}
}
