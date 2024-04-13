import Foundation
import Sargon

extension RequestedQuantity {
	public var isValid: Bool {
		switch (quantifier, quantity) {
		case (.exactly, 0):
			false
		case (_, ..<0):
			false
		default:
			true
		}
	}

	public static func exactly(_ quantity: Int) -> Self {
		.init(quantifier: .exactly, quantity: UInt16(quantity))
	}

	public static func atLeast(_ quantity: Int) -> Self {
		.init(quantifier: .atLeast, quantity: UInt16(quantity))
	}
}

// MARK: - RequestedQuantity + Codable
extension RequestedQuantity: Codable {
	public init(from decoder: any Decoder) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func encode(to encoder: any Encoder) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
