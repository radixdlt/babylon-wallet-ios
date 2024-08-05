import ComposableArchitecture
import SwiftUI

extension ChooseReceivingAccount.State {
	public enum AddressValidation: Sendable, Hashable {
		case valid(AccountAddress)
		case wrongNetwork(AccountAddress, incorrectNetwork: UInt8)
		case invalid
	}

	var validatedManualAccountAddress: AddressValidation {
		guard !manualAccountAddress.isEmpty,
		      !chooseAccounts.filteredAccounts.contains(where: { $0.address == manualAccountAddress })
		else {
			return .invalid
		}
		guard
			let addressOnSomeNetwork = try? AccountAddress(validatingAddress: manualAccountAddress)
		else {
			return .invalid
		}
		let networkOfAddress = addressOnSomeNetwork.networkID
		guard networkOfAddress == networkID else {
			loggerGlobal.warning("Manually inputted address is valid, but is on the WRONG network, inputted: \(networkOfAddress), but current network is: \(networkID.rawValue)")
			return .wrongNetwork(addressOnSomeNetwork, incorrectNetwork: networkOfAddress.rawValue)
		}
		return .valid(addressOnSomeNetwork)
	}

	var validatedAccountAddress: AccountAddress? {
		guard case let .valid(address) = validatedManualAccountAddress else {
			return nil
		}
		return address
	}

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
		@Perception.Bindable private var store: StoreOf<ChooseReceivingAccount>
		@FocusState private var focusedField: Bool

		public init(store: StoreOf<ChooseReceivingAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .medium2) {
							Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)

							addressField

							if !store.chooseAccounts.availableAccounts.isEmpty {
								Divider()

								Text(L10n.AssetTransfer.ChooseReceivingAccount.chooseOwnAccount)
							}

							ChooseAccounts.View(
								store: store.scope(state: \.chooseAccounts, action: \.child.chooseAccounts)
							)
							.opacity(store.canSelectOwnAccount ? 1.0 : 0.6)
							.disabled(!store.canSelectOwnAccount)
						}
						.padding(.medium3)
					}
					.destinations(with: store)
					.footer { chooseButton }
					.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.navigationTitle) {
						store.send(.view(.closeButtonTapped))
					}
				}
			}
		}

		private var addressField: some SwiftUI.View {
			AppTextField(
				placeholder: L10n.AssetTransfer.ChooseReceivingAccount.addressFieldPlaceholder,
				text: $store.manualAccountAddress.sending(\.view.manualAccountAddressChanged),
				hint: store.manualAddressHint,
				focus: .on(
					true,
					binding: $store.manualAccountAddressFocused.sending(\.view.focusChanged),
					to: $focusedField
				),
				showClearButton: true,
				innerAccessory: {
					Button(asset: AssetResource.qrCodeScanner) {
						store.send(.view(.scanQRCode))
					}
				}
			)
			.autocorrectionDisabled()
			.keyboardType(.alphabet)
		}

		private var chooseButton: some SwiftUI.View {
			WithControlRequirements(
				store.chooseAccounts.selectedAccounts?.first?.account,
				or: store.validatedAccountAddress,
				forAction: { result in
					let recipient: AccountOrAddressOf = switch result {
					case let .left(account): .profileAccount(value: account)
					case let .right(address): .addressOfExternalAccount(value: address)
					}
					store.send(.view(.chooseButtonTapped(recipient)))
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
		return navigationDestination(store: destinationStore.scope(state: \.scanAccountAddress, action: \.scanAccountAddress)) {
			ScanQRCoordinator.View(store: $0)
				.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.scanQRNavigationTitle, alwaysVisible: false)
		}
	}
}
