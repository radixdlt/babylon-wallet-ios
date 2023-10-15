import ComposableArchitecture
import SwiftUI

// MARK: - BIP39.WordList + Sendable
extension BIP39.WordList: @unchecked Sendable {}

// MARK: - BIP39.WordCount + Comparable
extension BIP39.WordCount: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

	mutating func increaseBy3() {
		guard self != .twentyFour else {
			assertionFailure("Invalid, cannot increase to than 24 words")
			return
		}
		self = .init(rawValue: rawValue + 3)!
	}

	mutating func decreaseBy3() {
		guard self != .twelve else {
			assertionFailure("Invalid, cannot decrease to less than 12 words")
			return
		}
		self = .init(rawValue: rawValue - 3)!
	}
}
