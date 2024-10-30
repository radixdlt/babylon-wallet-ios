extension EntitiesInvolvedClient: DependencyKey {
	static var liveValue: Self {
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient

		let getEntities: GetEntities = { request in
			let allAccounts = try await accountsClient.getAccountsOnNetwork(request.networkId)

			func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Account? {
				allAccounts.first { $0.address == accountAddress }
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ addresses: [AccountAddress]) throws -> OrderedSet<Account> {
				try .init(validating: addresses.compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ addresses: [IdentityAddress]) async throws -> OrderedSet<Persona> {
				try await .init(validating: addresses.asyncMap(identityFromComponentAddress))
			}

			let dataSource = request.dataSource

			return try await EntitiesInvolvedResult(
				identitiesRequiringAuth: mapIdentity(dataSource.addressesOfPersonasRequiringAuth),
				accountsRequiringAuth: mapAccount(dataSource.addressesOfAccountsRequiringAuth),
				accountsWithdrawnFrom: mapAccount(dataSource.addressesOfAccountsWithdrawnFrom),
				accountsDepositedInto: mapAccount(dataSource.addressesOfAccountsDepositedInto)
			)
		}

		return Self(
			getEntities: getEntities
		)
	}
}
