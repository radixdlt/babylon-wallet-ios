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
				ScrollView {
					LazyVStack {
						ForEach(viewStore.accounts) { account in
							//                            AddressView(
							//                                viewStore.address,
							//                                copyAddressAction: {
							//                                    viewStore.send(.copyAddressButtonTapped)
							//                                }
							//                            )
							//                            .foregroundColor(.app.whiteTransparent)
							Text(account.address.address)
						}
					}
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
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
