import AccountsClient
import FeaturePrelude

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	var viewState: CompletionMigrateOlympiaAccountsToBabylon.ViewState {
		let title: String = {
			switch migratedAccounts.count {
			case 0:
				return L10n.ImportLegacyWallet.Completion.titleNoAccounts
			case 1:
				return L10n.ImportLegacyWallet.Completion.titleOneAccount
			default:
				return L10n.ImportLegacyWallet.Completion.titleManyAccounts(migratedAccounts.count)
			}
		}()

		return .init(
			accounts: migratedAccounts,
			title: title
		)
	}
}

// MARK: - CompletionMigrateOlympiaAccountsToBabylon.View
extension CompletionMigrateOlympiaAccountsToBabylon {
	public struct ViewState: Equatable {
		let accounts: Profile.Network.Accounts
		let title: String
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
					Text(viewStore.title)
						.font(.app.body1Header)
						.padding()

					ScrollView {
						LazyVStack {
							ForEach(viewStore.accounts) { account in
								InnerCard {
									AddressView(.address(.account(account.address)))
								}
							}
						}
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .medium2)
				.footer {
					Button(L10n.Common.ok) {
						viewStore.send(.finishButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
			.navigationBarBackButtonHidden()
		}
	}
}

#if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - CompletionMigrateOlympiaAccountsToBabylon_Preview
// struct CompletionMigrateOlympiaAccountsToBabylon_Preview: PreviewProvider {
//	static var previews: some View {
//		CompletionMigrateOlympiaAccountsToBabylon.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: CompletionMigrateOlympiaAccountsToBabylon()
//			)
//		)
//	}
// }
//
// extension CompletionMigrateOlympiaAccountsToBabylon.State {
//	public static let previewValue = Self(
//		migratedAccounts: .previewValue
//	)
// }

#endif
