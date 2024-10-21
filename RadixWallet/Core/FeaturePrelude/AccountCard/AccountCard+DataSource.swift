import Foundation

// MARK: - AccountCardDataSource
struct AccountCardDataSource {
	let title: String?
	let ledgerIdentifiable: LedgerIdentifiable
	let gradient: Gradient
}

extension AccountCard {
	init(
		kind: Kind,
		account: Account,
		showName: Bool = true,
		@ViewBuilder trailing: () -> Trailing,
		@ViewBuilder bottom: () -> Bottom
	) {
		self.init(kind: kind, account: account.asDataSource(showName: showName), trailing: trailing, bottom: bottom)
	}
}

extension AccountCard where Trailing == EmptyView, Bottom == EmptyView {
	init(kind: Kind = .display, account: Account, showName: Bool = true) {
		self.init(
			kind: kind,
			account: account,
			showName: showName,
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

	init(kind: Kind = .display, account: AccountForDisplay) {
		self.init(
			kind: kind,
			account: account.asDataSource,
			trailing: { EmptyView() },
			bottom: { EmptyView() }
		)
	}

	init(kind: Kind = .innerCompact, account: InteractionReviewCommon.ReviewAccount) {
		switch account {
		case let .user(account):
			self.init(kind: kind, account: account)

		case let .external(accountAddress, _):
			self.init(kind: kind, account: accountAddress.asDataSource)
		}
	}
}

extension AccountCard where Bottom == EmptyView {
	init(kind: Kind, account: Account, showName: Bool = true, @ViewBuilder trailing: () -> Trailing) {
		self.init(
			kind: kind,
			account: account,
			showName: showName,
			trailing: trailing,
			bottom: { EmptyView() }
		)
	}

	init(kind: Kind = .display, account: AccountOrAddressOf, @ViewBuilder trailing: () -> Trailing) {
		self.init(
			kind: kind,
			account: account.asDataSource,
			trailing: trailing,
			bottom: { EmptyView() }
		)
	}
}

private extension Account {
	func asDataSource(showName: Bool) -> AccountCardDataSource {
		.init(
			title: showName ? displayName.rawValue : nil,
			ledgerIdentifiable: .address(of: self),
			gradient: .init(appearanceID)
		)
	}
}

private extension AccountForDisplay {
	var asDataSource: AccountCardDataSource {
		.init(title: displayName.value, ledgerIdentifiable: .address(.account(address)), gradient: .init(appearanceId))
	}
}

private extension AccountAddress {
	var asDataSource: AccountCardDataSource {
		.init(title: L10n.TransactionReview.externalAccountName, ledgerIdentifiable: .address(.account(self)), gradient: .external)
	}
}

private extension AccountOrAddressOf {
	var asDataSource: AccountCardDataSource {
		.init(title: title, ledgerIdentifiable: ledgerIdentifiable, gradient: gradient)
	}

	private var title: String {
		switch self {
		case let .profileAccount(account):
			account.displayName.value
		case .addressOfExternalAccount:
			L10n.Common.account
		}
	}

	private var ledgerIdentifiable: LedgerIdentifiable {
		switch self {
		case let .profileAccount(value: account):
			.address(.account(account.address))
		case let .addressOfExternalAccount(address):
			.address(.account(address))
		}
	}

	private var gradient: Gradient {
		switch self {
		case let .profileAccount(value: account):
			.init(account.appearanceID)
		case .addressOfExternalAccount:
			.external
		}
	}
}

private extension Gradient {
	static var external: Self {
		.init(colors: [.app.gray2])
	}
}
