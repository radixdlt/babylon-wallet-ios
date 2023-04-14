import Prelude

// MARK: - P2P.Dapp.Request.OneTimeAccountsRequestItem
extension P2P.Dapp.Request {
	public struct ResetRequestItem: Sendable, Hashable, Decodable {
		public let accounts: Bool
		public let personaData: Bool

		public init(
			accounts: Bool,
			personaData: Bool
		) {
			self.accounts = accounts
			self.personaData = personaData
		}
	}
}
