import Foundation

// MARK: - Token
public struct Token: Equatable, Identifiable {
	public let id = UUID()
	public let code: Code
	public let value: Float?
}

public extension Token {
	enum Code: String, CaseIterable {
		case btc
		case doge
		case dot
		case eth
		case ltc
		case sol
		case usdt
		case xrd
		case xrp

		public var value: String {
			rawValue.uppercased()
		}
	}
}

#if DEBUG
public extension Token {
	static let placeholder: Self = .init(
		code: Token.Code.allCases.randomElement() ?? .xrd,
		value: .random(in: 0 ... 1_000_000)
	)
}

public enum TokenRandomizer {
	public static func generateRandomTokens() -> [Token] {
		Token.Code.allCases.map {
			let randomValue: Float? = Bool.random() ? .random(in: 0 ... 100) : nil
			return Token(code: $0, value: randomValue)
		}
	}
}

#endif
