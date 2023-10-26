import Foundation

extension ProfileStore {
	public func hideAccount(_ account: Profile.Network.Account) async throws {
		try await updatingOnCurrentNetwork { network in
			network.hideAccount(account.address)
		}
	}

	public func hidePersona(_ persona: Profile.Network.Persona) async throws {
		try await updatingOnCurrentNetwork { network in
			network.hidePersona(persona)
		}
	}

	public func unhideAllEntities() async throws {
		try await updatingOnCurrentNetwork { network in
			network.unhideAllEntities()
		}
	}
}

extension ProfileStore {
	public func updatingOnCurrentNetwork(_ update: @Sendable (inout Profile.Network) async throws -> Void) async throws {
		try await updating { profile in
			var network = try await network()
			try await update(&network)
			try profile.updateOnNetwork(network)
		}
	}
}
