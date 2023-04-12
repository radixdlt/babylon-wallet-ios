import Prelude
import Profile

// MARK: - P2P.ToDapp.PersonaDataField
extension P2P.ToDapp {
	public typealias PersonaDataField = Profile.Network.Persona.Field.ID
}

// MARK: - P2P.ToDapp.PersonaData
extension P2P.ToDapp {
	public struct PersonaData: Sendable, Hashable, Encodable {
		public let field: PersonaDataField
		public let value: NonEmptyString

		public init(field: PersonaDataField, value: NonEmptyString) {
			self.field = field
			self.value = value
		}
	}
}
