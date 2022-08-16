import Foundation

// MARK: - Token
public struct Token: Equatable {
	let code: Code
	let value: Float
}

public extension Token {
	enum Code: String {
		case xrd

		public var value: String {
			rawValue.uppercased()
		}
	}
}
