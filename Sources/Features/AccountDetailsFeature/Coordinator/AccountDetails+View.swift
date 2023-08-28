import AccountPreferencesFeature
import AssetsFeature
import AssetTransferFeature
import EngineKit
import FeaturePrelude
import ImportMnemonicFeature
import ProfileBackupsFeature

extension AccountDetails.State {
	var viewState: AccountDetails.ViewState {
		.init(
			accountAddress: account.address,
			appearanceID: account.appearanceID,
			displayName: account.displayName.rawValue,
			callToAction: callToAction
		)
	}
}

// MARK: - AccountDetails.View
extension AccountDetails {
	public struct ViewState: Equatable {
		let accountAddress: AccountAddress
		let appearanceID: Profile.Network.Account.AppearanceID
		let displayName: String
		let callToAction: AccountDetails.State.CallToAction?
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

					Group {
						if let callToAction = viewStore.callToAction {
							switch callToAction {
							case .needToBackupMnemonicForThisAccount:
								exportMnemonicPromptView(viewStore)

							case .needToImportMnemonicForThisAccount:
								recoverMnemonicsPromptView(viewStore)
							}
						}
					}
					.padding(.medium1)

					Button(L10n.Account.transfer, asset: AssetResource.transfer) {
						viewStore.send(.transferButtonTapped)
					}
					.textStyle(.body1Header)
					.foregroundColor(.app.white)
					.padding(.horizontal, .large2)
					.frame(height: .standardButtonHeight)
					.background(.app.whiteTransparent3)
					.cornerRadius(.standardButtonHeight / 2)
					.padding(.bottom, .medium1)

					AssetsView.View(store: store.scope(state: \.assets, action: { .child(.assets($0)) }))
						.roundedCorners(.top, radius: .medium1)
						.ignoresSafeArea(edges: .bottom)
				}
				.background(viewStore.appearanceID.gradient)
				.navigationBarBackButtonHidden()
				.task {
					viewStore.send(.task)
				}
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
						Button(asset: AssetResource.ellipsis) {
							viewStore.send(.preferencesButtonTapped)
						}
						.frame(.small)
						.foregroundColor(.app.white)
					}
				}
				#endif
				.navigationDestination(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AccountDetails.Destinations.State.preferences,
					action: AccountDetails.Destinations.Action.preferences,
					destination: { AccountPreferences.View(store: $0) }
				)
				.fullScreenCover(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AccountDetails.Destinations.State.transfer,
					action: AccountDetails.Destinations.Action.transfer,
					content: { AssetTransfer.SheetView(store: $0) }
				)
				.fullScreenCover( /* Full Screen cover to not be able to use iOS dismiss gestures */
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AccountDetails.Destinations.State.exportMnemonic,
					action: AccountDetails.Destinations.Action.exportMnemonic,
					content: { store_ in
						NavigationView {
							ImportMnemonic.View(store: store_)
								// FIXME: Strings
								.navigationTitle("Backup Seed Phrase")
						}
					}
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AccountDetails.Destinations.State.importMnemonics,
					action: AccountDetails.Destinations.Action.importMnemonics,
					content: { ImportMnemonicsFlowCoordinator.View(store: $0) }
				)
			}
		}
	}
}

extension View {
	func recoverMnemonicsPromptView(_ viewStore: ViewStoreOf<AccountDetails>) -> some View {
		importMnemonicPromptView { viewStore.send(.recoverMnemonicsButtonTapped) }
	}

	func exportMnemonicPromptView(_ viewStore: ViewStoreOf<AccountDetails>) -> some View {
		backupMnemonicPromptView { viewStore.send(.exportMnemonicButtonTapped) }
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
