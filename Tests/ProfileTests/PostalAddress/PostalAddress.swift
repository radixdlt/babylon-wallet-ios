import CasePaths
import Foundation

extension PersonaFieldValue {
	public struct PostalAddress: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaFieldValue, Self> = /PersonaFieldValue.postalAddress
		public static var kind = PersonaFieldKind.postalAddress

		public let country: Country
	}
}
