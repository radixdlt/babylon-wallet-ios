import CasePaths
import Prelude

extension PersonaData {
	public struct Name: Sendable, Hashable, Codable, PersonaDataEntryProtocol {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.name
		public static var kind = PersonaData.Entry.Kind.name

		public enum Variant: String, Sendable, Hashable, Codable {
			/// order: `given middle family`
			case western

			/// order: `family (middle) given`
			case eastern
		}

		public let variant: Variant

		/// First/Given/Fore-name, .e.g. `"John"`
		public let given: String

		/// Middle name, e.g. `"Fitzgerald"`
		public let middle: String?

		/// Last/Family/Sur-name, .e.g. `"Kennedey"`
		public let family: String

		public init(given: String, middle: String? = nil, family: String, variant: Variant) {
			self.given = given
			self.middle = middle
			self.family = family
			self.variant = variant
		}
	}
}
