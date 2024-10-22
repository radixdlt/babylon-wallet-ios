extension InteractionReview.Sections {
	func simulateSections() async throws -> Common.SectionsData? {
		let xrdBalance: ResourceBalance = .init(resource: .init(resourceAddress: .sampleStokenetXRD, metadata: .init(name: "Radix", symbol: "XRD", isComplete: true)), details: .fungible(.init(isXRD: true, amount: .init(nominalAmount: .five))))
		let idResourceBalance = xrdBalance.asIdentified

		let nftBalance: ResourceBalance = .init(resource: .init(resourceAddress: .sampleMainnetNonFungibleGCMembership, atLedgerState: .init(version: 1, epoch: 2), metadata: .init(name: "GC Member Card", iconURL: .init(string: "https://stokenet-gumball-club.radixdlt.com/assets/member-card.png"), isComplete: true)), details: .nonFungible(.init(id: .sample, data: nil)))

		let accountWithdraw = Common.Account.State(
			account: .user(.sampleMainnetAlice),
			transfers: [idResourceBalance],
			isDeposit: false
		)
		let withdrawals = Common.Accounts.State(
			accounts: [accountWithdraw],
			enableCustomizeGuarantees: false
		)
		let accountDeposit = Common.Account.State(
			account: .user(.sampleMainnetBob),
			transfers: [idResourceBalance],
			isDeposit: true
		)
		let deposits = Common.Accounts.State(
			accounts: [accountDeposit],
			enableCustomizeGuarantees: false
		)

		let proofs = Common.Proofs.State(kind: .preAuthorization, proofs: [
			.init(resourceBalance: nftBalance),
		])

		return Common.SectionsData(
			withdrawals: withdrawals,
			deposits: deposits,
			proofs: proofs
		)
	}
}
