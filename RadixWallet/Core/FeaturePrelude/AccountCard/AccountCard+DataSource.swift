import Foundation

// MARK: - AccountCardDataSource
struct AccountCardDataSource {
	let title: String
	let ledgerIdentifiable: LedgerIdentifiable
	let gradient: Gradient
}

extension AccountCard {
	init(
		kind: Kind,
		account: Account,
		@ViewBuilder trailing: () -> Trailing,
		@ViewBuilder bottom: () -> Bottom
	) {
		self.init(kind: kind, account: account.asDataSource, trailing: trailing, bottom: bottom)
	}
}

extension AccountCard where Trailing == EmptyView, Bottom == EmptyView {
	init(kind: Kind = .display, account: Account) {
		self.init(
			kind: kind,
			account: account,
			trailing: { EmptyView() },
			bottom: { EmptyView() }
		)
	}

	init(kind: Kind, account: AccountCardDataSource) {
		self.init(
			kind: kind,
			account: account,
			trailing: { EmptyView() },
			bottom: { EmptyView() }
		)
	}
}

private extension Account {
	var asDataSource: AccountCardDataSource {
		.init(title: displayName.rawValue, ledgerIdentifiable: .address(of: self), gradient: .init(appearanceID))
	}
}
