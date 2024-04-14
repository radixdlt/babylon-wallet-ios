import Foundation
import Sargon

public typealias BIP39WordCount = Bip39WordCount

extension BIP39WordCount {
	public init?(wordCount: Int) {
		self.init(rawValue: UInt8(wordCount))
	}
}

// MARK: Identifiable
extension BIP39WordCount: Identifiable {
	public typealias ID = RawValue
	public var id: ID {
		rawValue
	}
}

// MARK: CaseIterable
extension BIP39WordCount: CaseIterable {
	public typealias AllCases = [Self]
	public static var allCases: [Self] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: Comparable
extension BIP39WordCount: Comparable {
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
