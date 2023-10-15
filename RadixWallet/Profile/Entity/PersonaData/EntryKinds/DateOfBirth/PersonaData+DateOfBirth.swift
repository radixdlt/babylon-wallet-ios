import EngineToolkitimport EngineToolkit
extension PersonaData {
	public struct DateOfBirth: Sendable, Hashable, Codable, PersonaDataEntryProtocol, CustomStringConvertible {
		public static let casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.dateOfBirth
		public static let kind = PersonaData.Entry.Kind.dateOfBirth

		public let date: Date

		public init(date: Date) {
			self.date = date
		}

		public init(
			year: Int,
			month: Int,
			day: Int,
			hour: Int = 12,
			minute: Int = 0,
			second: Int = 0,
			timezone: TimeZone = .gmt
		) throws {
			var dateComponents = DateComponents()
			dateComponents.calendar = .autoupdatingCurrent
			dateComponents.timeZone = timezone
			dateComponents.year = year
			dateComponents.month = month
			dateComponents.day = day
			dateComponents.hour = hour
			dateComponents.minute = minute
			dateComponents.second = second
			guard let date = dateComponents.date else {
				struct InvalidDateFromComponents: Swift.Error {}
				throw InvalidDateFromComponents()
			}
			self.init(date: date)
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(date.ISO8601Format())
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(
				date: Date(container.decode(String.self), strategy: .iso8601)
			)
		}

		public var description: String {
			date.ISO8601Format()
		}
	}
}
