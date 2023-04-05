import AccountsClient
import FeaturePrelude

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	var viewState: CompletionMigrateOlympiaAccountsToBabylon.ViewState {
		.init(accounts: migratedAccounts.babylonAccounts)
	}
}

// MARK: - CompletionMigrateOlympiaAccountsToBabylon.View
extension CompletionMigrateOlympiaAccountsToBabylon {
	public struct ViewState: Equatable {
		let accounts: Profile.Network.Accounts
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>

		public init(store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text(L10n.ImportLegacyWallet.Completion.title(viewStore.accounts.count))
						.font(.app.body1Header)
						.padding()

					ScrollView {
						LazyVStack {
							ForEach(viewStore.accounts) { account in
								InnerCard {
									AccountLabel(account: account) {
										viewStore.send(.copyAddress(account.address))
									}
								}
							}
						}
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .medium2)
				.footer {
					Button(L10n.ImportLegacyWallet.Completion.Button.finish) {
						viewStore.send(.finishButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
			.navigationBarBackButtonHidden()
		}
	}
}

extension AccountLabel {
	public init(
		account: Profile.Network.Account,
		copyAction: (() -> Void)? = nil
	) {
		self.init(
			account.displayName.rawValue,
			address: account.address.address,
			gradient: .init(account.appearanceID),
			height: .guaranteeAccountLabelHeight,
			copyAction: copyAction
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CompletionMigrateOlympiaAccountsToBabylon_Preview
struct CompletionMigrateOlympiaAccountsToBabylon_Preview: PreviewProvider {
	static var previews: some View {
		CompletionMigrateOlympiaAccountsToBabylon.View(
			store: .init(
				initialState: .previewValue,
				reducer: CompletionMigrateOlympiaAccountsToBabylon()
			)
		)
	}
}

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	public static let previewValue = Self(migratedAccounts: .previewValue)
}

extension MigratedAccounts {
	public static let previewValue: Self = {
		fatalError()
	}()
}
#endif
