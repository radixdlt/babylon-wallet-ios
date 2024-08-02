import ComposableArchitecture
import SwiftUI

extension ChooseReceivingAccount.State {
	var canSelectOwnAccount: Bool {
		manualAccountAddress.isEmpty
	}

	var manualAddressHint: Hint? {
		guard !manualAccountAddressFocused, !manualAccountAddress.isEmpty else {
			return .none
		}

		switch validatedManualAccountAddress {
		case .invalid:
			return .error(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
		case .wrongNetwork:
			return .error(L10n.AssetTransfer.Error.wrongNetwork)
		case let .valid(validAddress):
			if chooseAccounts.filteredAccounts.contains(where: { $0 == validAddress }) {
				return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
			}
			return .none
		}
	}
}

// MARK: - ChooseReceivingAccount.View
extension ChooseReceivingAccount {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseReceivingAccount>
		@FocusState private var focusedField: Bool

		public init(store: StoreOf<ChooseReceivingAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }) { viewStore in
					ScrollView {
						VStack(spacing: .medium2) {
							Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)

							addressField(viewStore)

							if !viewStore.chooseAccounts.availableAccounts.isEmpty {
								Divider()

								Text(L10n.AssetTransfer.ChooseReceivingAccount.chooseOwnAccount)
							}

							ChooseAccounts.View(
								store: store.scope(state: \.chooseAccounts, action: \.child.chooseAccounts)
							)
							.opacity(viewStore.canSelectOwnAccount ? 1.0 : 0.6)
							.disabled(!viewStore.canSelectOwnAccount)
						}
						.padding(.medium3)
					}
					.destinations(with: store)
					.footer { chooseButton(viewStore) }
					.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.navigationTitle) {
						viewStore.send(.view(.closeButtonTapped))
					}
				}
			}
		}

		private func addressField(_ viewStore: ViewStore<ChooseReceivingAccount.State, ChooseReceivingAccount.Action>) -> some SwiftUI.View {
			AppTextField(
				placeholder: L10n.AssetTransfer.ChooseReceivingAccount.addressFieldPlaceholder,
				text: viewStore.binding(
					get: \.manualAccountAddress,
					send: { .view(.manualAccountAddressChanged($0)) }
				),
				hint: viewStore.manualAddressHint,
				focus: .on(
					true,
					binding: viewStore.binding(
						get: \.manualAccountAddressFocused,
						send: { .view(.focusChanged($0)) }
					),
					to: $focusedField
				),
				showClearButton: true,
				innerAccessory: {
					Button {
						viewStore.send(.view(.scanQRCode))
					} label: {
						Image(asset: AssetResource.qrCodeScanner)
					}
				}
			)
			.autocorrectionDisabled()
			.keyboardType(.alphabet)
		}

		private func chooseButton(_ viewStore: ViewStore<ChooseReceivingAccount.State, ChooseReceivingAccount.Action>) -> some SwiftUI.View {
			WithControlRequirements(
				viewStore.chooseAccounts.selectedAccounts?.first?.account,
				or: viewStore.validatedAccountAddress,
				forAction: { result in
					let recipient: AccountOrAddressOf = switch result {
					case let .left(account): .profileAccount(value: account)
					case let .right(address): .addressOfExternalAccount(value: address)
					}
					viewStore.send(.view(.chooseButtonTapped(recipient)))
				},
				control: { action in
					Button(L10n.Common.choose, action: action)
						.buttonStyle(.primaryRectangular)
				}
			)
		}
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
