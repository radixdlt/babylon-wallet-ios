import Foundation
import Sargon

// MARK: - PersonaDataEntryName + Codable
extension PersonaDataEntryName: Codable {
	public init(from decoder: Decoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}

	public func encode(to encoder: Encoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}
}

// MARK: - PersonaDataEntryName.Variant
extension PersonaDataEntryName {
	public typealias Variant = Sargon.Variant
}

// MARK: - PersonaDataEntryName.Variant + CaseIterable
extension PersonaDataEntryName.Variant: CaseIterable {
	public typealias AllCases = [Self]
	public static var allCases: AllCases {
		[eastern, western]
	}
}
