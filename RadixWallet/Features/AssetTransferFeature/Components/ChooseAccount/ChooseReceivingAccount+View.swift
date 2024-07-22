import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccount.View
extension ChooseReceivingAccount {
	public struct ViewState: Equatable {
		var manualAccountAddress: String
		var manualAccountAddressFocused: Bool
		var chooseAccounts: ChooseAccounts.State
		var canSelectOwnAccount: Bool
		var validateAccountAddress: AccountAddress?
		var manualAddressHint: Hint?

		init(state: ChooseReceivingAccount.State) {
			manualAccountAddress = state.manualAccountAddress
			chooseAccounts = state.chooseAccounts
			manualAccountAddressFocused = state.manualAccountAddressFocused
			validateAccountAddress = state.validatedAccountAddress

			manualAddressHint = {
				guard !state.manualAccountAddressFocused, !state.manualAccountAddress.isEmpty else {
					return .none
				}

				switch state.validateManualAccountAddress() {
				case .invalid:
					return .iconError(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
				case .wrongNetwork:
					return .iconError(L10n.AssetTransfer.Error.wrongNetwork)
				case let .valid(validAddress):
					if state.chooseAccounts.filteredAccounts.contains(where: { $0 == validAddress }) {
						return .iconError(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
					}
					return .none
				}

			}()
			canSelectOwnAccount = manualAccountAddress.isEmpty
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseReceivingAccount>
		@FocusState private var focusedField: Bool

		public init(store: StoreOf<ChooseReceivingAccount>) {
			self.store = store
		}
	}
}

extension ChooseReceivingAccount.View {
	public var body: some View {
		NavigationStack {
			WithViewStore(store, observe: ChooseReceivingAccount.ViewState.init(state:), send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)

						addressField(viewStore)

						Divider()

						Text(L10n.AssetTransfer.ChooseReceivingAccount.chooseOwnAccount)

						ChooseAccounts.View(
							store: store.scope(
								state: \.chooseAccounts,
								action: { .child(.chooseAccounts($0)) }
							)
						)
						.opacity(viewStore.canSelectOwnAccount ? 1.0 : 0.6)
						.disabled(!viewStore.canSelectOwnAccount)
					}
					.padding(.medium3)
				}
				.destinations(with: store)
				.footer { chooseButton(viewStore) }
				.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.navigationTitle)
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
			}
		}
	}

	private func addressField(_ viewStore: ViewStoreOf<ChooseReceivingAccount>) -> some View {
		AppTextField(
			placeholder: L10n.AssetTransfer.ChooseReceivingAccount.addressFieldPlaceholder,
			text: viewStore.binding(
				get: \.manualAccountAddress,
				send: { .manualAccountAddressChanged($0) }
			),
			hint: viewStore.manualAddressHint,
			focus: .on(
				true,
				binding: viewStore.binding(
					get: \.manualAccountAddressFocused,
					send: { .focusChanged($0) }
				),
				to: $focusedField
			),
			showClearButton: true,
			innerAccessory: {
				Button {
					viewStore.send(.scanQRCode)
				} label: {
					Image(asset: AssetResource.qrCodeScanner)
				}
			}
		)
		.autocorrectionDisabled()
		.keyboardType(.alphabet)
	}

	private func chooseButton(_ viewStore: ViewStoreOf<ChooseReceivingAccount>) -> some View {
		WithControlRequirements(
			viewStore.chooseAccounts.selectedAccounts?.first?.account,
			or: viewStore.validateAccountAddress,
			forAction: { result in
				let recipient: AccountOrAddressOf = switch result {
				case let .left(account): .profileAccount(value: account)
				case let .right(address): .addressOfExternalAccount(value: address)
				}
				viewStore.send(.chooseButtonTapped(recipient))
			},
			control: { action in
				Button(L10n.Common.choose, action: action)
					.buttonStyle(.primaryRectangular)
			}
		)
	}
}

private extension StoreOf<ChooseReceivingAccount> {
	var destination: PresentationStoreOf<ChooseReceivingAccount.Destination> {
		func scopeState(state: State) -> PresentationState<ChooseReceivingAccount.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseReceivingAccount>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(
			store: destinationStore,
			state: /ChooseReceivingAccount.Destination.State.scanAccountAddress,
			action: ChooseReceivingAccount.Destination.Action.scanAccountAddress,
			destination: {
				ScanQRCoordinator.View(store: $0)
					.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.scanQRNavigationTitle, alwaysVisible: false)
			}
		)
	}
}
