import Foundation
@testable import Radix_Wallet_Dev

extension String {
	public var hexData: Data {
		try! Data(hex: self)
	}
}

extension FixedWidthInteger {
	var data: Data {
		let data = withUnsafeBytes(of: self) { Data($0) }
		return data
	}
}

// MARK: - UUID + ExpressibleByIntegerLiteral
extension UUID: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt16) {
		let hex = value.data.reversed().hex
		self.init(uuidString: "00000000-0000-0000-0000-00000000\(hex)")!
	}
}
