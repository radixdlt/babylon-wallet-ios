@testable import Cryptography
import CryptoKit
import Prelude

// MARK: - HD.Path.Full + ExpressibleByStringLiteral
extension HD.Path.Full: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		do {
			self = try .init(string: value)
		} catch {
			fatalError("Invalid string, error: \(String(describing: error))")
		}
	}
}

// MARK: - HD.Path.Relative + ExpressibleByStringLiteral
extension HD.Path.Relative: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		do {
			self = try .init(string: value)
		} catch {
			fatalError("Invalid string, error: \(String(describing: error))")
		}
	}
}

// MARK: - HD.Path.Component.Child + ExpressibleByIntegerLiteral
extension HD.Path.Component.Child: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: IntegerLiteralType) {
		self.init(nonHardenedValue: .init(value), isHardened: false)
	}
}

extension ECPublicKey {
	var hex: String {
		compressedRepresentation.hex()
	}
}

extension ECPrivateKey {
	var hex: String {
		rawRepresentation.hex()
	}
}

// MARK: - P256.Signing.PrivateKey + Equatable
extension P256.Signing.PrivateKey: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawRepresentation == rhs.rawRepresentation
	}
}

// MARK: - P256.Signing.PublicKey + Equatable
extension P256.Signing.PublicKey: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawRepresentation == rhs.rawRepresentation
	}
}
