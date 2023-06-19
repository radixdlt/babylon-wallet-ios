import Prelude
import Profile

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct PersonaDataRequestResponseItem: Sendable, Hashable, Encodable {
		public let fields: [PersonaDataEntryOfKind<PersonaDataEntry>]

		public init(
			fields: [PersonaDataEntryOfKind<PersonaDataEntry>]
		) {
			self.fields = fields
		}
	}
}
