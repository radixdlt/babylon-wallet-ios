import ComposableArchitecture
import SwiftUI

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	var viewState: CompletionMigrateOlympiaAccountsToBabylon.ViewState {
		let accounts = previouslyMigrated.map(\.viewStateAccount) + migrated.map(\.viewStateAccount)

		let subtitle = accounts.count == 1
			? L10n.ImportOlympiaAccounts.Completion.subtitleSingle
			: L10n.ImportOlympiaAccounts.Completion.subtitleMultiple

		return .init(
			title: L10n.ImportOlympiaAccounts.Completion.title,
			subtitle: subtitle,
			accounts: accounts
		)
	}
}

extension ImportOlympiaWalletCoordinator.MigratableAccount {
	var viewStateAccount: CompletionMigrateOlympiaAccountsToBabylon.ViewState.Account {
		.init(
			name: accountName,
			address: babylonAddress,
			previouslyMigrated: true,
			appearanceID: appearanceID
		)
	}
}

extension Profile.Network.Account {
	var viewStateAccount: CompletionMigrateOlympiaAccountsToBabylon.ViewState.Account {
		.init(
			name: displayName.rawValue,
			address: address,
			previouslyMigrated: false,
			appearanceID: appearanceID
		)
	}
}

// MARK: - CompletionMigrateOlympiaAccountsToBabylon.View
extension CompletionMigrateOlympiaAccountsToBabylon {
	public struct ViewState: Equatable {
		let title: String
		let subtitle: String
		let accounts: [Account]

		struct Account: Sendable, Hashable, Identifiable {
			var id: AccountAddress { address }
			let name: String?
			let address: AccountAddress
			let previouslyMigrated: Bool
			let appearanceID: Profile.Network.Account.AppearanceID
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>

		public init(store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					CloseButtonBar {
						viewStore.send(.closeButtonTapped)
					}

					ScrollView(showsIndicators: false) {
						VStack(spacing: 0) {
							Group {
								Text(viewStore.title)
									.textStyle(.sheetTitle)
									.padding(.bottom, .small2)

								Text(viewStore.subtitle)
									.textStyle(.body1Regular)
									.padding(.bottom, .medium3)
							}
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)

							VStack(spacing: .small2) {
								ForEach(viewStore.accounts) { account in
									AccountCard(account: account)
								}
							}
							.accountsBackground(count: 3, after: viewStore.accounts.last?.appearanceID)
							.padding(.horizontal, .large1 + .small1)
							.padding(.bottom, 2 * .large2)

							Text(L10n.ImportOlympiaAccounts.Completion.explanation)
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .medium1)
								.padding(.bottom, .medium1)
						}
					}
					.footer {
						Button(L10n.ImportOlympiaAccounts.Completion.accountListButtonTitle) {
							viewStore.send(.accountListButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
			.navigationBarBackButtonHidden()
		}
	}

	@MainActor
	struct AccountCard: SwiftUI.View {
		let account: ViewState.Account

		var body: some SwiftUI.View {
			VStack(spacing: .small1) {
				if let name = account.name {
					Text(name)
						.textStyle(.body1Header)
				}
				AddressView(.address(.account(account.address)))
					.opacity(0.8)
			}
			.foregroundColor(.app.white)
			.frame(maxWidth: .infinity)
			.padding(.vertical, .medium1)
			.background {
				RoundedRectangle(cornerRadius: .small1, style: .continuous)
					.fill(account.appearanceID.gradient)
			}
		}
	}
}

extension View {
	public func accountsBackground(count: Int, after lastAppearanceID: Profile.Network.Account.AppearanceID? = nil) -> some View {
		background(alignment: .bottom) {
			AccountCardsBackground(count: count, after: lastAppearanceID)
		}
	}
}

// MARK: - AccountCardsBackground
struct AccountCardsBackground: View {
	@State private var active = false
	let count: Int
	let indexedIDs: [(index: Int, id: Profile.Network.Account.AppearanceID)]

	init(count: Int, after lastAppearanceID: Profile.Network.Account.AppearanceID?) {
		self.count = count

		let last = lastAppearanceID.flatMap(Profile.Network.Account.AppearanceID.allCases.firstIndex) ?? 0
		self.indexedIDs = (0 ..< count).map { offset in
			(index: offset, id: Profile.Network.Account.AppearanceID.fromNumberOfAccounts(last + 1 + offset))
		}
	}

	var body: some View {
		ForEach(indexedIDs, id: \.id) { index, appearanceID in
			let opacity = index < 3 ? 0.2 : 0.1
			let i = Double(index + 1)
			dummyAccountCard(appearanceID: appearanceID)
				.opacity(active ? opacity : 0)
				.scaleEffect(active ? pow(0.9, i) : 1, anchor: .bottom)
				.offset(y: active ? i * .small1 : 0)
				.animation(.spring().delay(0.3), value: active)
		}
		.onAppear {
			active = true
		}
	}

	private func dummyAccountCard(appearanceID: Profile.Network.Account.AppearanceID) -> some View {
		RoundedRectangle(cornerRadius: .small1, style: .continuous)
			.fill(appearanceID.gradient)
			.frame(height: 2 * .large1)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - CompletionMigrateOlympiaAccountsToBabylon_Preview
struct CompletionMigrateOlympiaAccountsToBabylon_Preview: PreviewProvider {
	static var previews: some View {
		CompletionMigrateOlympiaAccountsToBabylon.View(
			store: .init(
				initialState: .previewValue,
				reducer: CompletionMigrateOlympiaAccountsToBabylon.init
			)
		)
	}
}

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	public static let previewValue = Self(
		previouslyMigrated: [],
		migrated: [.previewValue0, .previewValue1]
	)
}

#endif
