import Prelude
import Profile

// MARK: - P2P.Dapp.Response.PersonaDataField
extension P2P.Dapp.Response {
	public typealias PersonaDataField = Profile.Network.Persona.Field.ID
}

// MARK: - P2P.Dapp.Response.PersonaData
extension P2P.Dapp.Response {
	public struct PersonaData: Sendable, Hashable, Encodable {
		public let field: PersonaDataField
		public let value: NonEmptyString

		public init(field: PersonaDataField, value: NonEmptyString) {
			self.field = field
			self.value = value
		}
	}
}
