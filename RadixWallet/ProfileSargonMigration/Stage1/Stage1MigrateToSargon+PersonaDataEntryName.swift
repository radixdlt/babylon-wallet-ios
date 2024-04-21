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
	public typealias Variant = Sargon.PersonaDataNameVariant
}

extension PersonaDataEntryName {
	public var formatted: String {
		// Need to disable, since broken in swiftformat 0.52.7
		// swiftformat:disable redundantClosure
		let names = {
			switch variant {
			case .western: [givenNames, familyName]
			case .eastern: [familyName, givenNames]
			}
		}().compactMap { NonEmptyString($0) }
		// swiftformat:enable redundantClosure

		return [
			NonEmptyString(names.joined(separator: " ")),
			NonEmptyString(maybeString: nickname.nilIfEmpty.map { "\"\($0)\"" }),
		]
		.compactMap { $0 }
		.map(\.rawValue)
		.joined(separator: "\n")
	}
}

// MARK: - PersonaDataEntryName.Variant + CaseIterable
extension PersonaDataEntryName.Variant: CaseIterable {
	public typealias AllCases = [Self]
	public static var allCases: AllCases {
		[eastern, western]
	}
}
