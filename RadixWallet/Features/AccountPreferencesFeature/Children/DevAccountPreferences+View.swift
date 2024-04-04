#if DEBUG
import ComposableArchitecture
import SwiftUI
#endif // DEBUG

extension DevAccountPreferences.State {
	var viewState: DevAccountPreferences.ViewState {
		#if DEBUG
		return .init(
			canTurnIntoDappDefinitionAccounType: canTurnIntoDappDefinitionAccountType,
			canCreateAuthSigningKey: canCreateAuthSigningKey,
			createFungibleTokenButtonState: createFungibleTokenButtonState,
			createNonFungibleTokenButtonState: createNonFungibleTokenButtonState,
			createMultipleFungibleTokenButtonState: createMultipleFungibleTokenButtonState,
			createMultipleNonFungibleTokenButtonState: createMultipleNonFungibleTokenButtonState
		)
		#else
		return .init()
		#endif // DEBUG
	}
}

// MARK: - AccountPreferences.View
extension DevAccountPreferences {
	public struct ViewState: Equatable {
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
			canTurnIntoDappDefinitionAccounType: Bool,
			canCreateAuthSigningKey: Bool,
			createFungibleTokenButtonState: ControlState,
			createNonFungibleTokenButtonState: ControlState,
			createMultipleFungibleTokenButtonState: ControlState,
			createMultipleNonFungibleTokenButtonState: ControlState
		) {
			self.canTurnIntoDappDefinitionAccounType = canTurnIntoDappDefinitionAccounType
			self.canCreateAuthSigningKey = canCreateAuthSigningKey
			self.createFungibleTokenButtonState = createFungibleTokenButtonState
			self.createNonFungibleTokenButtonState = createNonFungibleTokenButtonState
			self.createMultipleFungibleTokenButtonState = createMultipleFungibleTokenButtonState
			self.createMultipleNonFungibleTokenButtonState = createMultipleNonFungibleTokenButtonState
		}
		#else
		public init() {}
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
					VStack {
						#if DEBUG
						turnIntoDappDefinitionAccountTypeButton(with: viewStore)
						createFungibleTokenButton(with: viewStore)
						// TODO: Re-enable. With new manifest builder that is not easy to handle.
						createNonFungibleTokenButton(with: viewStore)
						createMultipleFungibleTokenButton(with: viewStore)
						createMultipleNonFungibleTokenButton(with: viewStore)
						Spacer(minLength: 0)
						deleteAccountButton { store.send(.view(.deleteAccountButtonTapped)) }
						#endif // DEBUG
					}
					.multilineTextAlignment(.center)
					.frame(maxHeight: .infinity, alignment: .top)
					.padding(.medium1)
					.onAppear {
						viewStore.send(.appeared)
					}
					.navigationTitle("Dev Preferences")
					#if DEBUG
						.destinations(with: store)
					#endif
						.navigationBarTitleColor(.app.gray1)
						.navigationBarTitleDisplayMode(.inline)
						.navigationBarInlineTitleFont(.app.secondaryHeader)
						.toolbarBackground(.app.background, for: .navigationBar)
						.toolbarBackground(.visible, for: .navigationBar)
				}
			}
		}
	}
}

private extension StoreOf<DevAccountPreferences> {
	var destination: PresentationStoreOf<DevAccountPreferences.Destination> {
		func scopeState(state: State) -> PresentationState<DevAccountPreferences.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

#if DEBUG
@MainActor
private extension View {
	func destinations(with store: StoreOf<DevAccountPreferences>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.reviewTransaction, action: \.reviewTransaction)) {
			// FIXME: Should use DappInteractionClient instead to schedule a transaction
			TransactionReview.View(store: $0)
				.withNavigationBar(.topBarLeading) {
					store.send(.view(.closeTransactionButtonTapped))
				}
		}
	}
}

extension DevAccountPreferences.View {
	private func deleteAccountButton(action: @escaping () -> Void) -> some View {
		Button("DELETE ACCOUNT", action: action)
			.buttonStyle(.primaryRectangular(isDestructive: true))
	}

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
