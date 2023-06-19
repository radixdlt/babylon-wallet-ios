import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct PersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let fields: Set<PersonaDataEntryID>

		public init(
			fields: Set<PersonaDataEntryID>
		) {
			self.fields = fields
		}
	}
}
