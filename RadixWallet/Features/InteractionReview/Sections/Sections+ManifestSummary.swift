import Sargon

extension InteractionReview.Sections {
	func sections(for summary: ManifestSummary, networkID: NetworkID) async throws -> Common.SectionsData? {
		let allWithdrawAddresses = summary.accountWithdrawals.values.flatMap { $0 }.map(\.resourceAddress)
		//        let allDepositAddresses = summary.deposits.values.flatMap { $0 }.map(\.resourceAddress)

		// Pre-populate with all resource addresses from withdraw and deposit.
		let allAddresses: IdentifiedArrayOf<ResourceAddress> = Array(allWithdrawAddresses.uniqued()).asIdentified()

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
		//        let deposits = try await extractDeposits(
		//            accountDeposits: summary.deposits,
		//            entities: resourcesInfo,
		//            networkID: networkID
		//        )

		return Common.SectionsData(
			withdrawals: withdrawals
			//            deposits: deposits
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
			if resourceAddress.isFungible {
				switch resourceInfo {
				case let .left(resource):
					return try await [.known(onLedgerEntitiesClient.fungibleResourceBalance(
						resource,
						resourceAmount: .exact(ExactResourceAmount(nominalAmount: amount)),
						entities: entities,
						networkID: networkID,
						defaultDepositGuarantee: defaultDepositGuarantee
					))]
				case .right:
					return []
				}
			} else {
				return [.unknown]
			}
		case let .ids(resourceAddress, ids):
			return try await onLedgerEntitiesClient.nonFungibleResourceBalances(
				resourceInfo,
				resourceAddress: resourceAddress,
				resourceQuantifier: .byIds(ids: ids)
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
					break
				//                    let amount = bounds.
				//                    transfers.append(
				//                        try await .known(onLedgerEntitiesClient.fungibleResourceBalance(
				//                            resource,
				//                            resourceQuantifier: .guaranteed(decimal: amount),
				//                            entities: entities,
				//                            networkID: networkID,
				//                            defaultDepositGuarantee: defaultDepositGuarantee
				//                        ))
				//                    )
				case let .nonFungible(bounds):
					break
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
