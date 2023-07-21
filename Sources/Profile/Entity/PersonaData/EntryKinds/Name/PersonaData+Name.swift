import CasePaths
import Prelude

extension PersonaData {
	public struct Name: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.name
		public static var kind = PersonaData.Entry.Kind.fullName

		public enum Variant: String, Sendable, Hashable, Codable, CaseIterable {
			/// order: `given middle family`
			case western

			/// order: `family (middle) given`
			case eastern
		}

		public let variant: Variant

		public let familyName: String

		public let givenNames: String

		public let nickname: String?

		public init(
			variant: Variant,
			familyName: String,
			givenNames: String,
			nickname: String? = nil
		) {
			self.variant = variant
			self.familyName = familyName
			self.givenNames = givenNames
			self.nickname = nickname
		}

		public var description: String {
			let components: [String] = {
				switch variant {
				case .western: return [givenNames, familyName]
				case .eastern: return [familyName, givenNames]
				}
			}()

			let firstLine = components.joined(separator: " ")
			return """
			\(firstLine)\(nickname.map { "\n\($0)" } ?? "")
			"""
		}
	}
}
