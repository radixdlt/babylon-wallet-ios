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
	struct ViewState: Equatable {
		#if DEBUG
		var canTurnIntoDappDefinitionAccounType: Bool
		var canCreateAuthSigningKey: Bool
		var createFungibleTokenButtonState: ControlState
		var createNonFungibleTokenButtonState: ControlState
		var createMultipleFungibleTokenButtonState: ControlState
		var createMultipleNonFungibleTokenButtonState: ControlState
		#endif // DEBUG

		#if DEBUG
		init(
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
		init() {}
		#endif // DEBUG
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DevAccountPreferences>

		init(store: StoreOf<DevAccountPreferences>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
						Button("Create PreAuthorization") {
							viewStore.send(.createPreAuthorizationButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
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
					.radixToolbar(title: "Dev Preferences")
					#if DEBUG
						.destinations(with: store)
					#endif
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
				.withNavigationBar {
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
