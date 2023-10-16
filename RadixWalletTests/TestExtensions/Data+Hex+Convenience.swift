import Foundation
@testable import Radix_Wallet_Dev

extension String {
	public var hexData: Data {
		try! Data(hex: self)
	}
}
