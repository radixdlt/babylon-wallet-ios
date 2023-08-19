import EngineKit
import FeaturePrelude

extension AddAsset.State {
	var viewState: AddAsset.ViewState {
		.init(
			resourceAddress: resourceAddress,
			selectList: type,
			validatedResourceAddress: {
				guard let validatedResourceAddress,
				      !alreadyAddedResources.contains(validatedResourceAddress)
				else {
					return nil
				}
				return validatedResourceAddress
			}(),
			addressHint: {
				guard !resourceAddressFieldFocused, !resourceAddress.isEmpty else {
					return .none
				}

				guard let validatedAddress = validatedResourceAddress else {
					return .error(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
				}

				if alreadyAddedResources.contains(validatedAddress) {
					return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
				}

				return .none
			}(),
			resourceAddressFieldFocused: resourceAddressFieldFocused
		)
	}
}

extension AddAsset {
	public struct ViewState: Equatable {
		let resourceAddress: String
		let selectList: AllowDenyAssets.State.List
		let validatedResourceAddress: ResourceAddress?
		let addressHint: Hint?
		let resourceAddressFieldFocused: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AddAsset>

		@FocusState private var resourceAddressFieldFocus: Bool

		init(store: StoreOf<AddAsset>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: Action.view) { viewStore in
				VStack {
					CloseButton(action: {})
						.flushedLeft
					ScrollView {
						VStack(spacing: .medium1) {
							titleView
							instructionsView

							resourceAddressView(viewStore)
							depositListSelectionView(viewStore)
							addAssetButton(viewStore)
						}
						.padding([.horizontal, .bottom], .medium1)
					}
					.scrollIndicators(.hidden)
				}
			}
			.presentationDetents([.fraction(0.75)])
			.presentationDragIndicator(.visible)
			#if os(iOS)
				.presentationBackground(.blur)
			#endif
		}
	}
}

extension AddAsset.View {
	@ViewBuilder
	var titleView: some SwiftUI.View {
		Text("Add an Asset")
			.textStyle(.sheetTitle)
			.foregroundColor(.app.gray1)
	}

	@ViewBuilder
	var instructionsView: some SwiftUI.View {
		Text("Enter the asset’s resource address (starting with “reso”)")
			.lineLimit(nil)
			.textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
			.multilineTextAlignment(.center)
			.fixedSize(horizontal: false, vertical: true)
	}

	@ViewBuilder
	func resourceAddressView(_ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		AppTextField(
			placeholder: "Resource Address",
			text: viewStore.binding(
				get: \.resourceAddress,
				send: { .resourceAddressChanged($0) }
			),
			hint: viewStore.addressHint,
			focus: .on(
				true,
				binding: viewStore.binding(
					get: \.resourceAddressFieldFocused,
					send: { .focusChanged($0) }
				),
				to: $resourceAddressFieldFocus
			),
			showClearButton: true
		)
	}

	func depositListSelectionView(_ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		FlowLayout {
			ForEach(AllowDenyAssets.State.List.allCases, id: \.self) {
				depositSelectOptionView(type: $0, viewStore)
			}
		}
	}

	@ViewBuilder
	func depositSelectOptionView(type: AllowDenyAssets.State.List, _ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		HStack {
			RadioButton(
				appearance: .dark,
				state: viewStore.selectList == type ? .selected : .unselected
			)
			Text(type.selectionText)
		}
		.onTapGesture {
			viewStore.send(.addTypeChanged(type))
		}
	}

	@ViewBuilder
	func addAssetButton(_ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		WithControlRequirements(
			viewStore.validatedResourceAddress,
			forAction: {
				viewStore.send(.addAssetTapped($0))
			},
			control: { action in
				Button("Add Asset", action: action)
					.buttonStyle(.primaryRectangular)
			}
		)
	}
}

extension AllowDenyAssets.State.List {
	var selectionText: String {
		switch self {
		case .allow:
			return "Allow Deposits"
		case .deny:
			return "Deny Deposits"
		}
	}
}
