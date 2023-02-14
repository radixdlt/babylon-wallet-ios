import Prelude

extension P2P.ToDapp {
	public struct Persona: Sendable, Hashable, Encodable {
		public let identityAddress: String
		public let label: String

		public init(identityAddress: String, label: String) {
			self.identityAddress = identityAddress
			self.label = label
		}
	}
}
