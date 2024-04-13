// MARK: - Profile.Network
extension Profile {
	// MARK: - Profile.Network
	/// **For a given network**: a list of accounts, personas and connected dApps.
	public struct Network:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible
	{
		/// The ID of the network that has been used to generate the accounts, to which personas
		/// have been added and dApps connected.
		public let networkID: NetworkID

		public typealias Accounts = IdentifiedArrayOf<Account>

		/// An identifiable ordered set of `Account`s created by the user for this network.
		private var accounts: Accounts

		public typealias Personas = IdentifiedArrayOf<Persona>
		/// An identifiable ordered set of `Persona`s created by the user for this network.
		private var personas: Personas

		public typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
		/// An identifiable ordered set of `AuthorizedDapp`s the user has connected to.
		var authorizedDapps: AuthorizedDapps

		public init(
			networkID: NetworkID,
			accounts: Accounts,
			personas: Personas,
			authorizedDapps: AuthorizedDapps
		) {
			self.networkID = networkID
			self.accounts = accounts
			self.personas = personas
			self.authorizedDapps = authorizedDapps
		}
	}
}

extension Profile.Network {
	public var description: String { "A Profile network" }
}
