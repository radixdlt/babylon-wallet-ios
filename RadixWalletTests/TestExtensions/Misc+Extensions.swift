import Foundation
@testable import Radix_Wallet_Dev

extension String {
	var hexData: Data {
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

// MARK: - Mnemonic + ExpressibleByStringLiteral
extension Mnemonic: ExpressibleByStringLiteral {
	public init(stringLiteral phrase: String) {
		try! self.init(phrase: phrase, language: .english)
	}
}
