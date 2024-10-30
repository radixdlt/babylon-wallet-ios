// MARK: - EntitiesInvolvedClient
struct EntitiesInvolvedClient: Sendable {
	var getEntities: GetEntities
}

// MARK: EntitiesInvolvedClient.GetEntities
extension EntitiesInvolvedClient {
	typealias GetEntities = @Sendable (GetEntitiesRequest) async throws -> EntitiesInvolvedResult
}

// MARK: EntitiesInvolvedClient.GetEntitiesRequest
extension EntitiesInvolvedClient {
	struct GetEntitiesRequest: Sendable {
		let networkId: NetworkId
		let dataSource: EntitiesInvolvedDataSource
	}
}

// MARK: - EntitiesInvolvedResult
struct EntitiesInvolvedResult: Sendable, Hashable {
	/// A set of all MY personas or accounts in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	var entitiesRequiringAuth: OrderedSet<AccountOrPersona> {
		OrderedSet(accountsRequiringAuth.map { .account($0) } + identitiesRequiringAuth.map { .persona($0) })
	}

	let identitiesRequiringAuth: OrderedSet<Persona>
	let accountsRequiringAuth: OrderedSet<Account>

	/// A set of all MY accounts in the manifest which were deposited into. This is a subset of the addresses seen in `accountsRequiringAuth`.
	let accountsWithdrawnFrom: OrderedSet<Account>

	/// A set of all MY accounts in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	let accountsDepositedInto: OrderedSet<Account>
}
