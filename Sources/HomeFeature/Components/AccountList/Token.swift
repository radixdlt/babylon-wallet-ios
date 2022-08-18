import Foundation

// MARK: - Token
public extension Home.AccountRow {
	struct Token: Equatable {
		let code: Code
		let value: Float
	}
}

public extension Home.AccountRow.Token {
	enum Code: String {
		case xrd

		public var value: String {
			rawValue.uppercased()
		}
	}
}
