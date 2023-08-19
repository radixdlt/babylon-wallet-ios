import EngineKit
import FeaturePrelude

extension AddAsset.State {
	var viewState: AddAsset.ViewState {
		.init(
			resourceAddress: resourceAddress,
			selectList: type,
			validatedResourceAddress: validatedResourceAddress,
			addressHint: {
				guard !resourceAddressFieldFocused, !resourceAddress.isEmpty else {
					return .none
				}

				guard let validatedAddress = validatedResourceAddress else {
					return .error(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
				}

				switch type {
				case .allow where currentAllowList.contains(validatedAddress):
					return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
				case .deny where currentDenyList.contains(validatedAddress):
					return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
				default:
					return .none
				}
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
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .medium1) {
					Text("Add an Asset")
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
					Text("Enter the asset’s resource address (starting with “reso”)")
						.lineLimit(nil)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)

					AppTextField(
						placeholder: "Resource Address",
						text: viewStore.binding(
							get: \.resourceAddress,
							send: { .view(.resourceAddressChanged($0)) }
						),
						hint: viewStore.addressHint,
						focus: .on(
							true,
							binding: viewStore.binding(
								get: \.resourceAddressFieldFocused,
								send: { .view(.focusChanged($0)) }
							),
							to: $resourceAddressFieldFocus
						),
						showClearButton: true
					)
					FlowLayout {
						HStack {
							RadioButton(
								appearance: .dark,
								state: viewStore.selectList == .allow ? .selected : .unselected
							)
							Text("Allow Deposits")
						}
						.onTapGesture {
							viewStore.send(.view(.addTypeChanged(.allow)))
						}

						HStack {
							RadioButton(
								appearance: .dark,
								state: viewStore.selectList == .deny ? .selected : .unselected
							)
							Text("Deny Deposits")
						}
						.onTapGesture {
							viewStore.send(.view(.addTypeChanged(.deny)))
						}
					}

					WithControlRequirements(
						viewStore.validatedResourceAddress,
						forAction: {
							viewStore.send(.view(.addAssetTapped($0)))
						},
						control: { action in
							Button("Add Asset", action: action)
								.buttonStyle(.primaryRectangular)
						}
					)

					Spacer()
				}
				.padding(.medium1)
			}
			.presentationDetents([.medium])
			.presentationDragIndicator(.visible)
			#if os(iOS)
				.presentationBackground(.blur)
			#endif
		}
	}
}
