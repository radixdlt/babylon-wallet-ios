import ComposableArchitecture
import SwiftUI

extension ChooseTransferRecipient.State {
	enum ReceiverValidation: Sendable, Hashable {
		case valid(TransferReceiver)
		case wrongNetwork(AccountAddress, incorrectNetwork: UInt8)
		case invalid
	}

	enum TransferReceiver: Sendable, Hashable {
		case accountAddress(AccountAddress)
		case rnsDomain(RnsDomain)
	}

	var validatedManualReceiverValidation: ReceiverValidation {
		guard !manualTransferReceiver.isEmpty,
		      !chooseAccounts.filteredAccounts.contains(where: { $0.address == manualTransferReceiver })
		else {
			return .invalid
		}
		guard
			let addressOnSomeNetwork = try? AccountAddress(validatingAddress: manualTransferReceiver)
		else {
			return .invalid
		}
		let networkOfAddress = addressOnSomeNetwork.networkID
		guard networkOfAddress == networkID else {
			loggerGlobal.warning("Manually inputted address is valid, but is on the WRONG network, inputted: \(networkOfAddress), but current network is: \(networkID.rawValue)")
			return .wrongNetwork(addressOnSomeNetwork, incorrectNetwork: networkOfAddress.rawValue)
		}
		return .valid(.accountAddress(addressOnSomeNetwork))
	}

	var validatedAccountAddress: AccountAddress? {
		guard case let .valid(.accountAddress(address)) = validatedManualReceiverValidation else {
			return nil
		}
		return address
	}

	var canSelectOwnAccount: Bool {
		manualTransferReceiver.isEmpty
	}

	var manualReceiverHint: Hint.ViewState? {
		guard !manualTransferReceiverFocused, !manualTransferReceiver.isEmpty else {
			return .none
		}

		switch validatedManualReceiverValidation {
		case .invalid:
			return .error(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
		case .wrongNetwork:
			return .error(L10n.AssetTransfer.Error.wrongNetwork)
		case let .valid(.accountAddress(validAddress)):
			if chooseAccounts.filteredAccounts.contains(where: { $0 == validAddress }) {
				return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
			}
			return .none
		case let .valid(.rnsDomain(domain)):
			return .none
		}
	}
}

// MARK: - ChooseReceivingAccount.View
extension ChooseTransferRecipient {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<ChooseTransferRecipient>
		@FocusState private var focusedField: Bool

		init(store: StoreOf<ChooseTransferRecipient>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .medium2) {
							Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
								.textStyle(.body1Regular)
								.foregroundColor(.primaryText)

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
					.background(.primaryBackground)
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
				text: $store.manualTransferReceiver.sending(\.view.manualTransferReceiverChanged),
				hint: store.manualReceiverHint,
				focus: .on(
					true,
					binding: $store.manualTransferReceiverFocused.sending(\.view.focusChanged),
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
					case let .left(account): .profileAccount(
							value: account.forDisplay
						)
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

private extension StoreOf<ChooseTransferRecipient> {
	var destination: PresentationStoreOf<ChooseTransferRecipient.Destination> {
		func scopeState(state: State) -> PresentationState<ChooseTransferRecipient.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseTransferRecipient>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.scanTransferReceiver, action: \.scanTransferReceiver)) {
			ScanQRCoordinator.View(store: $0)
				.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.scanQRNavigationTitle, alwaysVisible: false)
		}
	}
}
