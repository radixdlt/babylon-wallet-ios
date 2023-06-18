import CasePaths
import Prelude

extension PersonaDataEntry {
	public struct DateOfBirth: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static let casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.dateOfBirth
		public static let kind = PersonaFieldKind.dateOfBirth

		public let date: Date

		public init(date: Date) {
			self.date = date
		}

		public init(year: Int, month: Int, day: Int) throws {
			var dateComponents = DateComponents()
			dateComponents.year = year
			dateComponents.month = month
			dateComponents.day = day
			guard let date = dateComponents.date else {
				struct InvalidDateFromComponents: Swift.Error {}
				throw InvalidDateFromComponents()
			}
			self.init(date: date)
		}
	}
}
