import ComposableArchitecture
import SwiftUI

extension ChooseTransferRecipient.State {
	enum ManualRecipientValidation: Sendable, Hashable {
		case valid(ManualTransferRecipient)
		case wrongNetwork(AccountAddress, incorrectNetwork: UInt8)
		case invalidAccountAddress
		case invalidRnsDomain
	}

	enum ManualTransferRecipient: Sendable, Hashable {
		case accountAddress(AccountAddress)
		case rnsDomain(RnsDomain)
	}

	var validatedManualRecipientValidation: ManualRecipientValidation {
		guard !sanitizedManualTransferRecipient.isEmpty else {
			return .invalidAccountAddress
		}

		if sanitizedManualTransferRecipient.isRnsDomain {
			do {
				let domain = try rnsDomainValidated(domain: sanitizedManualTransferRecipient)
				return .valid(.rnsDomain(domain))
			} catch {
				return .invalidRnsDomain
			}
		}

		guard !chooseAccounts.filteredAccounts.contains(where: { $0.address == sanitizedManualTransferRecipient })
		else {
			return .invalidAccountAddress
		}
		guard
			let addressOnSomeNetwork = try? AccountAddress(validatingAddress: sanitizedManualTransferRecipient)
		else {
			return .invalidAccountAddress
		}
		let networkOfAddress = addressOnSomeNetwork.networkID
		guard networkOfAddress == networkID else {
			loggerGlobal.warning("Manually inputted address is valid, but is on the WRONG network, inputted: \(networkOfAddress), but current network is: \(networkID.rawValue)")
			return .wrongNetwork(addressOnSomeNetwork, incorrectNetwork: networkOfAddress.rawValue)
		}
		return .valid(.accountAddress(addressOnSomeNetwork))
	}

	var validatedManualTransferRecipient: ManualTransferRecipient? {
		guard case let .valid(recipient) = validatedManualRecipientValidation else {
			return nil
		}
		return recipient
	}

	var canSelectOwnAccount: Bool {
		manualTransferRecipient.isEmpty
	}

	var manualReceiverHint: Hint.ViewState? {
		guard !manualTransferRecipientFocused, !manualTransferRecipient.isEmpty else {
			return .none
		}

		switch validatedManualRecipientValidation {
		case .invalidAccountAddress:
			return .error(L10n.AssetTransfer.ChooseReceivingAccount.invalidAddressError)
		case .invalidRnsDomain:
			return .error("Invalid Domain")
		case .wrongNetwork:
			return .error(L10n.AssetTransfer.Error.wrongNetwork)
		case let .valid(.accountAddress(validAddress)):
			if chooseAccounts.filteredAccounts.contains(where: { $0 == validAddress }) {
				return .error(L10n.AssetTransfer.ChooseReceivingAccount.alreadyAddedError)
			}
			return .none
		case .valid(.rnsDomain):
			return .none
		}
	}
}

// MARK: - ChooseTransferRecipient.View
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
						Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
							.padding(.vertical, .medium3)

						VStack(spacing: .medium2) {
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
						.padding([.horizontal, .bottom], .medium3)
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
				text: $store.manualTransferRecipient.sending(\.view.manualTransferRecipientChanged),
				hint: store.manualReceiverHint,
				focus: .on(
					true,
					binding: $store.manualTransferRecipientFocused.sending(\.view.focusChanged),
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
			.textInputAutocapitalization(.never)
			.keyboardType(.alphabet)
		}

		private var chooseButton: some SwiftUI.View {
			WithControlRequirements(
				store.chooseAccounts.selectedAccounts?.first?.account,
				or: store.validatedManualTransferRecipient,
				forAction: { result in
					store.send(.view(.chooseButtonTapped(result)))
				},
				control: { action in
					Button(L10n.Common.choose, action: action)
						.buttonStyle(.primaryRectangular)
				}
			)
			.controlState(store.isDeterminingRnsDomainRecipient ? .loading(.local) : .enabled)
		}
	}
}

private extension StoreOf<ChooseTransferRecipient> {
	var destination: PresentationStoreOf<ChooseTransferRecipient.Destination> {
		func scopeState(state: State) -> PresentationState<ChooseTransferRecipient.Destination.State> {
			state.$destination
		}
		return scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ChooseTransferRecipient>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.scanTransferRecipient, action: \.scanTransferRecipient)) {
			ScanQRCoordinator.View(store: $0)
				.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.scanQRNavigationTitle, alwaysVisible: false)
		}
		.alert(store: destinationStore.scope(state: \.domainResolutionErrorAlert, action: \.domainResolutionErrorAlert))
	}
}
