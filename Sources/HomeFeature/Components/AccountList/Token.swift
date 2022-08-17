import Foundation

// MARK: - Token
public extension Home.AccountList {
	struct Token: Equatable {
		let code: Code
		let value: Float
	}
}

public extension Home.AccountList.Token {
	enum Code: String {
		case xrd

		public var value: String {
			rawValue.uppercased()
		}
	}
}
