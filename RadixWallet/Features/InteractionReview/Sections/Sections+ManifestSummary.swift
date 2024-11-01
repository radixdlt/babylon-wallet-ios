import Sargon

extension InteractionReview.Sections {
	func sections(for summary: ManifestSummary, networkID: NetworkID) async throws -> Common.SectionsData? {
		let allWithdrawAddresses = summary.accountWithdrawals.values.flatMap { $0 }.map(\.resourceAddress)
		let allDepositAddresses = summary.accountDeposits.values.flatMap { $0 }.flatMap(\.specifiedResources.keys)

		// Pre-populate with all resource addresses from withdraw and deposit.
		let allAddresses: IdentifiedArrayOf<ResourceAddress> = Array((allWithdrawAddresses + allDepositAddresses).uniqued()).asIdentified()

		func resourcesInfo(_ resourceAddresses: [ResourceAddress]) async throws -> ResourcesInfo {
			try await onLedgerEntitiesClient.getResources(resourceAddresses)
				.reduce(into: ResourcesInfo()) { partialResult, next in
					partialResult[next.resourceAddress] = .left(next)
				}
		}

		let resourcesInfo = try await resourcesInfo(allAddresses.elements)

		let withdrawals = try await extractWithdrawals(
			accountWithdraws: summary.accountWithdrawals,
			entities: resourcesInfo,
			networkID: networkID
		)

		// Extract Deposits section
		let deposits = try await extractDeposits(
			accountDeposits: summary.accountDeposits,
			entities: resourcesInfo,
			networkID: networkID
		)

		return Common.SectionsData(
			withdrawals: withdrawals,
			deposits: deposits
		)
	}

	private func extractWithdrawals(
		accountWithdraws: [AccountAddress: [AccountWithdraw]],
		entities: ResourcesInfo = [:],
		networkID: NetworkID
	) async throws -> Common.Accounts.State? {
		var withdrawals: [Common.ReviewAccount: IdentifiedArrayOf<Common.Transfer>] = [:]
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(Array(accountWithdraws.keys))

		for (accountAddress, accountWithdrawals) in accountWithdraws {
			let account = try userAccounts.account(for: accountAddress)
			let transfers = try await accountWithdrawals.asyncFlatMap {
				try await transferInfo(
					accountWithdraw: $0,
					entities: entities,
					networkID: networkID
				)
			}
			.map(\.asIdentified)

			withdrawals[account, default: []].append(contentsOf: transfers)
		}

		guard !withdrawals.isEmpty else { return nil }

		let withdrawalAccounts = withdrawals.map {
			Common.Account.State(account: $0.key, transfers: $0.value, isDeposit: false)
		}
		.asIdentified()

		return .init(accounts: withdrawalAccounts, enableCustomizeGuarantees: false)
	}

	private func extractDeposits(
		accountDeposits: [AccountAddress: [AccountDeposit]],
		entities: ResourcesInfo = [:],
		networkID: NetworkID
	) async throws -> Common.Accounts.State? {
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(Array(accountDeposits.keys))
		let defaultDepositGuarantee = await appPreferencesClient.getPreferences().transaction.defaultDepositGuarantee

		var deposits: [Common.ReviewAccount: IdentifiedArrayOf<Common.Transfer>] = [:]

		for (accountAddress, accountDeposits) in accountDeposits {
			let account = try userAccounts.account(for: accountAddress)
			let transfers = try await accountDeposits.asyncFlatMap {
				let aux = try await transferInfo(
					accountDeposit: $0,
					entities: entities,
					networkID: networkID,
					defaultDepositGuarantee: defaultDepositGuarantee
				)
				return aux
			}
			.map(\.asIdentified)

			deposits[account, default: []].append(contentsOf: transfers)
		}

		let depositAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { Common.Account.State(account: $0.key, transfers: $0.value, isDeposit: true) }
			.asIdentified()

		guard !depositAccounts.isEmpty else { return nil }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty
		return .init(accounts: depositAccounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	func transferInfo(
		accountWithdraw: AccountWithdraw,
		entities: ResourcesInfo = [:],
		networkID: NetworkID,
		defaultDepositGuarantee: Decimal192 = 1
	) async throws -> [ResourceBalance] {
		let resourceAddress = accountWithdraw.resourceAddress
		guard let resourceInfo = entities[resourceAddress] else {
			throw ResourceEntityNotFound(address: resourceAddress.address)
		}

		switch accountWithdraw {
		case let .amount(_, amount):
			switch resourceInfo {
			case let .left(resource):
				if resourceAddress.isFungible {
					return try await [.known(onLedgerEntitiesClient.fungibleResourceBalance(
						resource,
						resourceAmount: .exact(.init(nominalAmount: amount)),
						entities: entities,
						networkID: networkID,
						defaultDepositGuarantee: defaultDepositGuarantee
					))]
				} else {
					return [.known(.init(resource: resource, details: .nonFungible(.amount(amount: .exact(.init(nominalAmount: amount))))))]
				}
			case .right:
				return []
			}
		case let .ids(resourceAddress, ids):
			return try await onLedgerEntitiesClient.nonFungibleResourceBalances(
				resourceInfo,
				resourceAddress: resourceAddress,
				ids: ids
			)
			.map(\.toResourceBalance)
		}
	}

	func transferInfo(
		accountDeposit: AccountDeposit,
		entities: ResourcesInfo = [:],
		networkID: NetworkID,
		defaultDepositGuarantee: Decimal192 = 1
	) async throws -> [ResourceBalance] {
		var transfers: [ResourceBalance] = []

		for (resourceAddress, resourceBounds) in accountDeposit.specifiedResources {
			guard let resourceInfo = entities[resourceAddress] else {
				throw ResourceEntityNotFound(address: resourceAddress.address)
			}

			switch resourceInfo {
			case let .left(resource):
				switch resourceBounds {
				case let .fungible(bounds):
					try await transfers.append(
						.known(onLedgerEntitiesClient.fungibleResourceBalance(
							resource,
							resourceAmount: .init(bounds: bounds),
							entities: entities,
							networkID: networkID,
							defaultDepositGuarantee: defaultDepositGuarantee
						))
					)
				case let .nonFungible(bounds):
					if !bounds.certainIds.isEmpty {
						try await transfers.append(
							contentsOf:
							onLedgerEntitiesClient.nonFungibleResourceBalances(
								resourceInfo,
								resourceAddress: resourceAddress,
								ids: bounds.certainIds
							)
							.map(\.toResourceBalance)
						)
					}

					if case let .notExact(certainIds, _, upperBound, _) = bounds {
						switch upperBound {
						case let .inclusive(amount):
							if Double(certainIds.count) < amount.asDouble {
								transfers.append(.known(.init(
									resource: resource,
									details: .nonFungible(.amount(amount: .between(
										minimum: .init(nominalAmount: 2),
										maximum: .init(nominalAmount: 5)
									)))
								)))
							}
						case .unbounded:
							transfers.append(.known(.init(
								resource: resource,
								details: .nonFungible(.amount(amount: .unknown))
							)))
						}
					}
				}
			case .right:
				break
			}
		}

		if case .mayBePresent = accountDeposit.unspecifiedResources {
			transfers.append(.unknown)
		}

		return transfers
	}
}

extension AccountWithdraw {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .amount(resourceAddress, _):
			resourceAddress
		case let .ids(resourceAddress, _):
			resourceAddress
		}
	}
}

extension SimpleNonFungibleResourceBounds {
	var certainIds: [NonFungibleLocalId] {
		switch self {
		case let .exact(_, certainIds):
			certainIds
		case let .notExact(certainIds, _, _, _):
			certainIds
		}
	}
}
