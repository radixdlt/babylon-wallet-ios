import Sargon

extension InteractionReview.Sections {
	func sections(for summary: ManifestSummary, networkID: NetworkID) async throws -> Common.SectionsData? {
		/// Only GeneralSubintent classification is allowed for PreAuth transactions
		guard summary.classification.first == .generalSubintent else {
			return nil
		}

		let allWithdrawAddresses = summary.accountWithdrawals.values.flatMap { $0 }.map(\.resourceAddress)
		let allDepositAddresses = summary.accountDeposits.values.flatMap(\.specifiedResources).map(\.resourceAddress)

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

		let deposits = try await extractDeposits(
			accountDeposits: summary.accountDeposits,
			entities: resourcesInfo,
			networkID: networkID
		)

		let dappAddresses = extractDappAddresses(encounteredAddresses: summary.encounteredEntities)
		let dAppsUsed = try await extractDapps(
			addresses: dappAddresses,
			unknownTitle: L10n.TransactionReview.unknownComponents,
			showPossibleDappCalls: true
		)

		let proofs = try await exctractProofs(summary.presentedProofs)

		return Common.SectionsData(
			withdrawals: withdrawals,
			dAppsUsed: dAppsUsed,
			deposits: deposits,
			proofs: proofs
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
			Common.Account.State(account: $0.key, transfers: $0.value, purpose: .withdrawal)
		}
		.asIdentified()

		return .init(accounts: withdrawalAccounts, enableCustomizeGuarantees: false)
	}

	private func extractDeposits(
		accountDeposits: [AccountAddress: AccountDeposits],
		entities: ResourcesInfo = [:],
		networkID: NetworkID
	) async throws -> Common.Accounts.State? {
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(Array(accountDeposits.keys))
		var deposits: [Common.ReviewAccount: IdentifiedArrayOf<Common.Transfer>] = [:]

		for (accountAddress, accountDeposits) in accountDeposits {
			let account = try userAccounts.account(for: accountAddress)
			var transfers = try await transferInfo(
				accountDeposits: accountDeposits,
				entities: entities,
				networkID: networkID
			)

			if case .mayBePresent = accountDeposits.unspecifiedResources {
				transfers.append(.unknown)
			}

			deposits[account, default: []].append(contentsOf: transfers.map(\.asIdentified))
		}

		let depositAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { Common.Account.State(account: $0.key, transfers: $0.value, purpose: .deposit) }
			.asIdentified()

		guard !depositAccounts.isEmpty else { return nil }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty
		return .init(accounts: depositAccounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	private func transferInfo(
		accountWithdraw: AccountWithdraw,
		entities: ResourcesInfo = [:],
		networkID: NetworkID
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
						resourceAmount: .exact(amount),
						networkID: networkID
					))]
				} else {
					@Dependency(\.resourcesVisibilityClient) var resourcesVisibilityClient
					let isHidden = try await resourcesVisibilityClient.isHidden(.nonFungible(resourceAddress))
					return [.known(.init(resource: resource, details: .nonFungible(.amount(amount: .exact(amount))), isHidden: isHidden))]
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

	private func transferInfo(
		accountDeposits: AccountDeposits,
		entities: ResourcesInfo = [:],
		networkID: NetworkID
	) async throws -> [ResourceBalance] {
		var transfers: [ResourceBalance] = []

		for resourceBounds in accountDeposits.specifiedResources {
			let resourceAddress = resourceBounds.resourceAddress
			guard let resourceInfo = entities[resourceAddress] else {
				throw ResourceEntityNotFound(address: resourceAddress.address)
			}

			switch resourceInfo {
			case let .left(resource):
				switch resourceBounds {
				case let .fungible(_, bounds):
					try await transfers.append(
						.known(onLedgerEntitiesClient.fungibleResourceBalance(
							resource,
							resourceAmount: .init(bounds: bounds),
							networkID: networkID
						))
					)
				case let .nonFungible(_, bounds):
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

					if let additionalAmount = bounds.additionalAmount {
						let resourceAmount = ResourceAmount(bounds: additionalAmount)
						transfers.append(.known(.init(
							resource: resource,
							details: .nonFungible(.amount(amount: resourceAmount))
						)))
					}
				}
			case .right:
				break
			}
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

extension SimpleResourceBounds {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .fungible(resourceAddress, _):
			resourceAddress
		case let .nonFungible(resourceAddress, _):
			resourceAddress
		}
	}
}
