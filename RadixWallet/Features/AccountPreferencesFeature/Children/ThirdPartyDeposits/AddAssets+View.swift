import ComposableArchitecture
import SwiftUI

extension AddAsset.State {
	var viewState: AddAsset.ViewState {
		.init(
			resourceAddress: resourceAddress,
			validatedResourceAddress: validatedResourceAddress.validAddress,
			addressHint: {
				guard !resourceAddressFieldFocused, !resourceAddress.isEmpty else {
					return .none
				}

				switch validatedResourceAddress {
				case .valid:
					return .none
				case .wrongNetwork:
					return .iconError(L10n.AssetTransfer.Error.wrongNetwork)
				case .alreadyAdded:
					return .iconError(L10n.AssetTransfer.Error.resourceAlreadyAdded)
				case .invalid:
					return .iconError(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
				}
			}(),
			resourceAddressFieldFocused: resourceAddressFieldFocused,
			mode: mode
		)
	}
}

extension AddAsset {
	struct ViewState: Equatable {
		let resourceAddress: String
		let validatedResourceAddress: ResourceViewState.Address?
		let addressHint: Hint.ViewState?
		let resourceAddressFieldFocused: Bool
		let mode: ResourcesListMode
	}

	@MainActor
	struct View: SwiftUI.View {
		@Environment(\.colorScheme) private var colorScheme
		let store: StoreOf<AddAsset>

		@FocusState private var resourceAddressFieldFocus: Bool

		init(store: StoreOf<AddAsset>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: Action.view) { viewStore in
				VStack(spacing: .zero) {
					VStack(spacing: .medium3) {
						titleView(viewStore.mode.title)
						instructionsView(viewStore.mode.instructions)

						resourceAddressView(viewStore)
						if case .allowDenyAssets = viewStore.mode {
							depositListSelectionView(viewStore)
						}
					}
					Spacer()
				}
				.padding(.horizontal, .medium3)
				.background(.primaryBackground)
				.footer {
					addAssetButton(viewStore)
				}
				.withNavigationBar {
					viewStore.send(.closeTapped)
				}
				.presentationDetents([.fraction(viewStore.mode.detentsFraction)])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
			}
		}
	}
}

extension AddAsset.View {
	@ViewBuilder
	func titleView(_ text: String) -> some SwiftUI.View {
		Text(text)
			.multilineTextAlignment(.center)
			.textStyle(.sheetTitle)
			.foregroundColor(.primaryText)
	}

	@ViewBuilder
	func instructionsView(_ text: String) -> some SwiftUI.View {
		Text(text)
			.lineLimit(nil)
			.textStyle(.body1Regular)
			.foregroundColor(.primaryText)
			.multilineTextAlignment(.center)
			.fixedSize(horizontal: false, vertical: true)
	}

	@ViewBuilder
	func resourceAddressView(_ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		AppTextField(
			placeholder: L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetInputHint,
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
			ForEach(ResourcesListMode.ExceptionRule.allCases, id: \.self) {
				depositExceptionSelectionView($0, viewStore)
			}
		}
	}

	@ViewBuilder
	func depositExceptionSelectionView(_ exception: ResourcesListMode.ExceptionRule, _ viewStore: ViewStoreOf<AddAsset>) -> some SwiftUI.View {
		HStack(spacing: .small3) {
			RadioButton(
				appearance: colorScheme == .light ? .dark : .light,
				state: viewStore.mode.allowDenyAssets == exception ? .selected : .unselected
			)
			Text(exception.selectionText)
		}
		.onTapGesture {
			viewStore.send(.exceptionRuleChanged(exception))
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
				Button(viewStore.mode.addButtonTitle, action: action)
					.buttonStyle(.primaryRectangular)
			}
		)
	}
}

extension ResourcesListMode.ExceptionRule {
	var selectionText: String {
		switch self {
		case .allow:
			L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetAllow
		case .deny:
			L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetDeny
		}
	}
}

private extension ResourcesListMode {
	var allowDenyAssets: ResourcesListMode.ExceptionRule? {
		guard case let .allowDenyAssets(type) = self else {
			return nil
		}
		return type
	}

	var title: String {
		switch self {
		case .allowDenyAssets:
			L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetTitle
		case .allowDepositors:
			L10n.AccountSettings.ThirdPartyDeposits.addDepositorTitle
		}
	}

	var instructions: String {
		switch self {
		case .allowDenyAssets:
			L10n.AccountSettings.SpecificAssetsDeposits.addAnAssetSubtitle
		case .allowDepositors:
			L10n.AccountSettings.ThirdPartyDeposits.addDepositorSubtitle
		}
	}

	var detentsFraction: CGFloat {
		switch self {
		case .allowDenyAssets:
			0.6
		case .allowDepositors:
			0.55
		}
	}
}
