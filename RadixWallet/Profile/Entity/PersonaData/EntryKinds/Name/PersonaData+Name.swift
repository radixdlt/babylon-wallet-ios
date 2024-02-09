// MARK: - PersonaData.Name
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

		public let nickname: String

		public init(
			variant: Variant,
			familyName: String,
			givenNames: String,
			nickname: String
		) {
			self.variant = variant
			self.familyName = familyName
			self.givenNames = givenNames
			self.nickname = nickname
		}

		public var description: String {
			let components: [String] = switch variant {
			case .western: [givenNames, nickname, familyName]
			case .eastern: [familyName, nickname, givenNames]
			}
			return components.joined(separator: " ")
		}

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
}

extension String {
	var nilIfEmpty: String? {
		isEmpty ? nil : self
	}
}
