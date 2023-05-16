import Prelude
import Profile

extension P2P.Dapp.Response {
	public struct Persona: Sendable, Hashable, Encodable {
		public let identityAddress: IdentityAddress
		public let label: String

		public init(identityAddress: IdentityAddress, label: NonEmptyString) {
			self.identityAddress = identityAddress
			self.label = label.rawValue
		}

		public init(persona: Profile.Network.Persona) {
			self.init(identityAddress: persona.address, label: persona.displayName)
		}
	}
}
