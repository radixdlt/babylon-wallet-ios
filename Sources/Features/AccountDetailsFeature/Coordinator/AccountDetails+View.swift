import AccountPreferencesFeature
import AssetTransferFeature
import FeaturePrelude

extension AccountDetails.State {
	var viewState: AccountDetails.ViewState {
		.init(
			accountAddress: account.address,
			appearanceID: account.appearanceID,
			displayName: account.displayName.rawValue,
			isLoadingResources: isLoadingResources
		)
	}
}

// MARK: - AccountDetails.View
extension AccountDetails {
	public struct ViewState: Equatable {
		let accountAddress: AccountAddress
		let appearanceID: Profile.Network.Account.AppearanceID
		let displayName: String
		let isLoadingResources: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDetails>

		public init(store: StoreOf<AccountDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					AddressView(.address(.account(viewStore.accountAddress)))
						.foregroundColor(.app.whiteTransparent)
						.textStyle(.body2HighImportance)
						.padding(.bottom, .medium1)

					Button("Transfer", asset: AssetResource.transfer) {
						viewStore.send(.transferButtonTapped)
					}
					.textStyle(.body1Header)
					.foregroundColor(.app.white)
					.padding(.horizontal, .large2)
					.frame(height: .standardButtonHeight)
					.background(.app.whiteTransparent3)
					.cornerRadius(.standardButtonHeight / 2)
					.padding(.bottom, .medium1)

					if viewStore.isLoadingResources {
						ProgressView()
					}
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
				.navigationBarBackButtonHidden()
				#if os(iOS)
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								viewStore.send(.backButtonTapped)
							}
							.foregroundColor(.app.white)
						}
						ToolbarItem(placement: .principal) {
							Text(viewStore.displayName)
								.textStyle(.secondaryHeader)
								.foregroundColor(.app.white)
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							Button(action: { viewStore.send(.preferencesButtonTapped) }) {
								Image(asset: AssetResource.ellipsis)
							}
							.frame(.small)
							.foregroundColor(.app.white)
						}
					}
				#endif
					.onAppear {
						viewStore.send(.appeared)
					}
					.task {
						viewStore.send(.task)
					}
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /AccountDetails.Destinations.State.preferences,
						action: AccountDetails.Destinations.Action.preferences,
						content: { AccountPreferences.View(store: $0) }
					)
					.fullScreenCover(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /AccountDetails.Destinations.State.transfer,
						action: AccountDetails.Destinations.Action.transfer,
						content: { AssetTransfer.View(store: $0) }
					)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			AccountDetails.View(
				store: .init(
					initialState: .init(for: .previewValue0),
					reducer: AccountDetails()
				)
			)
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}
}
#endif
