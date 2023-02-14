import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude

// MARK: - AccountDetails.View
extension AccountDetails {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

extension AccountDetails.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .zero) {
					NavigationBar(
						titleText: viewStore.displayName,
						leadingItem: BackButton {
							viewStore.send(.dismissAccountDetailsButtonTapped)
						},
						trailingItem: accountPreferencesButton(with: viewStore)
					)
					.foregroundColor(.app.white)
					.padding([.horizontal, .top], .medium3)

					AddressView(
						viewStore.address,
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.foregroundColor(.app.whiteTransparent)
					.padding(.bottom, .medium1)

					// TODO: @davdroman take care of proper Asset Transfer implementation
					// when we have the proper spec and designs
//					#if DEBUG // FF
//					Button(
//						"Transfer",
//						action: { viewStore.send(.transferButtonTapped) }
//					)
//					.buttonStyle(.secondaryRectangular())
//					.padding(.bottom)
//					#endif

					ScrollView {
						VStack(spacing: .medium3) {
							AssetsView.View(
								store: store.scope(
									state: \.assets,
									action: { .child(.assets($0)) }
								)
							)
						}
						.padding(.bottom, .medium1)
					}
					.refreshable {
						await viewStore.send(.pullToRefreshStarted).finish()
					}
					.background(Color.app.gray5)
					.padding(.bottom, .medium2)
					.cornerRadius(.medium2)
					.padding(.bottom, .medium2 * -2)
				}
				.background(viewStore.appearanceID.gradient)
			}
			.onAppear {
				viewStore.send(.appeared)
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AccountDetails.Destinations.State.transfer,
				action: AccountDetails.Destinations.Action.transfer,
				content: { AssetTransfer.View(store: $0) }
			)
		}
	}
}

// MARK: - AccountDetails.View.AccountDetailsViewStore
extension AccountDetails.View {
	fileprivate typealias AccountDetailsViewStore = ViewStore<AccountDetails.View.ViewState, AccountDetails.Action.ViewAction>
}

// MARK: - Private Methods
extension AccountDetails.View {
	fileprivate func accountPreferencesButton(with viewStore: AccountDetailsViewStore) -> some View {
		Button(
			action: {
				viewStore.send(.displayAccountPreferencesButtonTapped)
			}, label: {
				Image(asset: AssetResource.ellipsis)
			}
		)
		.frame(.small)
	}
}

// MARK: - AccountDetails.View.ViewState
extension AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let appearanceID: OnNetwork.Account.AppearanceID
		let address: AddressView.ViewState
		let displayName: String

		init(state: AccountDetails.State) {
			appearanceID = state.account.appearanceID
			address = .init(address: state.address.address, format: .short())
			displayName = state.displayName
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.View(
			store: .init(
				initialState: .init(for: .previewValue),
				reducer: AccountDetails()
			)
		)
	}
}
#endif
