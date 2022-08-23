import Foundation

// MARK: - Token
public extension Home.AccountRow {
	struct Token: Equatable, Identifiable {
		public let id = UUID()
		let code: Code
		let value: Float
	}
}

public extension Home.AccountRow.Token {
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
public extension Home.AccountRow.Token {
	static let placeholder: Self = .init(
		code: Home.AccountRow.Token.Code.allCases.randomElement() ?? .xrd,
		value: .random(in: 0 ... 1_000_000)
	)
}

public enum TokenRandomizer {
	static func generateRandomTokens(_ limit: Int = 10) -> [Home.AccountRow.Token] {
		(1 ..< .random(in: 1 ... limit)).map { _ in
			Home.AccountRow.Token(
				code: Home.AccountRow.Token.Code.allCases.randomElement() ?? .xrd,
				value: .random(in: 0 ... 1_000_000)
			)
		}
	}
}

#endif
