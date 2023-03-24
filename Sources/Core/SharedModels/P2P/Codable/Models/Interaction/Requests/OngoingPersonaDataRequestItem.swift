import Prelude

// MARK: - P2P.FromDapp.WalletInteraction.OngoingPersonaDataRequestItem
extension P2P.FromDapp.WalletInteraction {
	public struct OngoingPersonaDataRequestItem: Sendable, Hashable, Decodable {
		public let fields: [P2P.FromDapp.PersonaDataField]

		public init(fields: [P2P.FromDapp.PersonaDataField]) {
			self.fields = fields
		}
	}
}
