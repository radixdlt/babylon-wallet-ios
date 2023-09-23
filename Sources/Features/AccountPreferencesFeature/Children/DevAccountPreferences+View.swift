import FeaturePrelude
import ShowQRFeature

#if DEBUG
// Manifest turning account into Dapp Definition type, debug action...
import TransactionReviewFeature
#endif // DEBUG

extension DevAccountPreferences.State {
	var viewState: DevAccountPreferences.ViewState {
		#if DEBUG
		return .init(
			isOnMainnet: isOnMainnet,
			faucetButtonState: faucetButtonState,
			canTurnIntoDappDefinitionAccounType: canTurnIntoDappDefinitionAccountType,
			canCreateAuthSigningKey: canCreateAuthSigningKey,
			createFungibleTokenButtonState: createFungibleTokenButtonState,
			createNonFungibleTokenButtonState: createNonFungibleTokenButtonState,
			createMultipleFungibleTokenButtonState: createMultipleFungibleTokenButtonState,
			createMultipleNonFungibleTokenButtonState: createMultipleNonFungibleTokenButtonState
		)
		#else
		return .init(isOnMainnet: isOnMainnet, faucetButtonState: faucetButtonState)
		#endif // DEBUG
	}
}

// MARK: - AccountPreferences.View
extension DevAccountPreferences {
	public struct ViewState: Equatable {
		public let isOnMainnet: Bool
		public var faucetButtonState: ControlState

		#if DEBUG
		public var canTurnIntoDappDefinitionAccounType: Bool
		public var canCreateAuthSigningKey: Bool
		public var createFungibleTokenButtonState: ControlState
		public var createNonFungibleTokenButtonState: ControlState
		public var createMultipleFungibleTokenButtonState: ControlState
		public var createMultipleNonFungibleTokenButtonState: ControlState
		#endif // DEBUG

		#if DEBUG
		public init(
			isOnMainnet: Bool,
			faucetButtonState: ControlState,
			canTurnIntoDappDefinitionAccounType: Bool,
			canCreateAuthSigningKey: Bool,
			createFungibleTokenButtonState: ControlState,
			createNonFungibleTokenButtonState: ControlState,
			createMultipleFungibleTokenButtonState: ControlState,
			createMultipleNonFungibleTokenButtonState: ControlState
		) {
			self.isOnMainnet = isOnMainnet
			self.faucetButtonState = faucetButtonState
			self.canTurnIntoDappDefinitionAccounType = canTurnIntoDappDefinitionAccounType
			self.canCreateAuthSigningKey = canCreateAuthSigningKey
			self.createFungibleTokenButtonState = createFungibleTokenButtonState
			self.createNonFungibleTokenButtonState = createNonFungibleTokenButtonState
			self.createMultipleFungibleTokenButtonState = createMultipleFungibleTokenButtonState
			self.createMultipleNonFungibleTokenButtonState = createMultipleNonFungibleTokenButtonState
		}
		#else
		public init(isOnMainnet: Bool, faucetButtonState: ControlState) {
			self.isOnMainnet = isOnMainnet
			self.faucetButtonState = faucetButtonState
		}
		#endif // DEBUG
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DevAccountPreferences>

		public init(store: StoreOf<DevAccountPreferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					VStack(alignment: .leading) {
						if !viewStore.isOnMainnet {
							faucetButton(with: viewStore)
						}
						#if DEBUG
						turnIntoDappDefinitionAccountTypeButton(with: viewStore)
						createFungibleTokenButton(with: viewStore)
						// TODO: Re-enable. With new manifest builder that is not easy to handle.
						// createNonFungibleTokenButton(with: viewStore)
						// createMultipleFungibleTokenButton(with: viewStore)
						// createMultipleNonFungibleTokenButton(with: viewStore)
						#endif // DEBUG
						qrCodeButton(with: viewStore)
					}
					.frame(maxHeight: .infinity, alignment: .top)
					.padding(.medium1)
					.onAppear {
						viewStore.send(.appeared)
					}
					.navigationTitle("Dev Preferences")
					.sheet(
						store: store.destination,
						state: /DevAccountPreferences.Destination.State.showQR,
						action: DevAccountPreferences.Destination.Action.showQR
					) { store in
						ShowQR.View(store: store)
					}
					#if DEBUG
					.sheet(
							store: store.destination,
							state: /DevAccountPreferences.Destination.State.reviewTransaction,
							action: DevAccountPreferences.Destination.Action.reviewTransaction
						) { store in
							// FIXME: Should use DappInteractionClient intstead to schedule a transaction
							NavigationView {
								TransactionReview.View(store: store)
							}
						}
					#endif // DEBUG
					#if os(iOS)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.toolbarBackground(.app.background, for: .navigationBar)
					.toolbarBackground(.visible, for: .navigationBar)
					#endif // os(iOS)
				}
			}
		}
	}
}

private extension StoreOf<DevAccountPreferences> {
	var destination: PresentationStoreOf<DevAccountPreferences.Destination> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
	}
}

extension DevAccountPreferences.View {
	@ViewBuilder
	private func faucetButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button(L10n.AccountSettings.getXrdTestTokens) {
			viewStore.send(.faucetButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.faucetButtonState)

		if viewStore.faucetButtonState.isLoading {
			Text(L10n.AccountSettings.loadingPrompt)
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}

	@ViewBuilder
	private func qrCodeButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button(L10n.AccountSettings.showQR) {
			viewStore.send(.qrCodeButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
	}
}

#if DEBUG
extension DevAccountPreferences.View {
	@ViewBuilder
	private func turnIntoDappDefinitionAccountTypeButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button("Turn into dApp Definition account type") {
			viewStore.send(.turnIntoDappDefinitionAccountTypeButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.canTurnIntoDappDefinitionAccounType ? .enabled : .disabled)
	}

	@ViewBuilder
	private func createFungibleTokenButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button("Create Fungible Token") {
			viewStore.send(.createFungibleTokenButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.createFungibleTokenButtonState)

		if viewStore.createFungibleTokenButtonState.isLoading {
			Text("Creating Token")
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}

	@ViewBuilder
	private func createNonFungibleTokenButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button("Create NFT") {
			viewStore.send(.createNonFungibleTokenButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.createNonFungibleTokenButtonState)

		if viewStore.createNonFungibleTokenButtonState.isLoading {
			Text("Creating NFT")
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}

	@ViewBuilder
	private func createMultipleFungibleTokenButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button("Create Multiple Fungible Tokens") {
			viewStore.send(.createMultipleFungibleTokenButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.createMultipleFungibleTokenButtonState)

		if viewStore.createMultipleFungibleTokenButtonState.isLoading {
			Text("Creating Tokens")
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}

	@ViewBuilder
	private func createMultipleNonFungibleTokenButton(with viewStore: ViewStoreOf<DevAccountPreferences>) -> some View {
		Button("Create Multiple NFTs") {
			viewStore.send(.createMultipleNonFungibleTokenButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.createMultipleNonFungibleTokenButtonState)

		if viewStore.createMultipleNonFungibleTokenButtonState.isLoading {
			Text("Creating NFTs")
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

#endif // DEBUG

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountPreferences_Preview: PreviewProvider {
	static var previews: some View {
		DevAccountPreferences.View(
			store: .init(
				initialState: .init(address: try! .init(validatingAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6")),
				reducer: DevAccountPreferences.init
			)
		)
	}
}
#endif
