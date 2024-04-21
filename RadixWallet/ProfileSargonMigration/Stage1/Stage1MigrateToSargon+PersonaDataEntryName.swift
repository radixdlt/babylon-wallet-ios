import Foundation
import Sargon

// MARK: - PersonaDataEntryName.Variant
extension PersonaDataEntryName {
	public typealias Variant = Sargon.PersonaDataNameVariant
}

// MARK: - PersonaDataEntryName.Variant + CaseIterable
extension PersonaDataEntryName.Variant: CaseIterable {
	public typealias AllCases = [Self]
	public static var allCases: AllCases {
		[eastern, western]
	}
}
