import ComposableArchitecture
import SwiftUI

extension ChooseTransferRecipient.State {
	enum ManualRecipientValidation: Hashable {
		case valid(ManualTransferRecipient)
		case wrongNetwork(AccountAddress, incorrectNetwork: UInt8)
		case invalidAccountAddress
		case invalidRnsDomain
	}

	enum ManualTransferRecipient: Hashable {
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

	var validatedManualAccountAddress: AccountAddress? {
		guard case let .valid(.accountAddress(address)) = validatedManualRecipientValidation else {
			return nil
		}
		return address
	}

	var matchingAddressBookEntryForManualAddress: AddressBookEntry? {
		guard let address = validatedManualAccountAddress else {
			return nil
		}
		return addressBookEntries.first(where: { $0.address == address })
	}

	var canStoreValidatedManualRecipientInAddressBook: Bool {
		guard let address = validatedManualAccountAddress else {
			return false
		}
		guard matchingAddressBookEntryForManualAddress == nil else {
			return false
		}
		return !chooseAccounts.availableAccounts.contains(where: { $0.address == address })
	}

	var selectableAddressBookEntries: [AddressBookEntry] {
		addressBookEntries.filter { entry in
			!chooseAccounts.filteredAccounts.contains(entry.address)
		}
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
		@Environment(\.colorScheme) private var colorScheme

		init(store: StoreOf<ChooseTransferRecipient>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .zero) {
							VStack(spacing: .medium2) {
								Text(L10n.AssetTransfer.ChooseReceivingAccount.enterManually)
									.textStyle(.body1Regular)
									.foregroundColor(.primaryText)
									.padding(.vertical, .medium3)

								addressField
								manualAddressBookStatus
							}
							.padding([.horizontal, .bottom], .medium3)

							Picker("", selection: $store.selectedTab.sending(\.view.tabChanged)) {
								Text(L10n.AssetTransfer.ChooseReceivingAccount.myAccounts)
									.tag(ChooseTransferRecipient.RecipientTab.myAccounts)
								Text(L10n.AssetTransfer.ChooseReceivingAccount.addressBook)
									.tag(ChooseTransferRecipient.RecipientTab.addressBook)
							}
							.pickerStyle(.segmented)
							.padding(.horizontal, .medium3)
							.padding(.vertical, .medium3)

							if store.selectedTab == .myAccounts {
								ChooseAccounts.View(
									store: store.scope(state: \.chooseAccounts, action: \.child.chooseAccounts)
								)
								.opacity(store.canSelectOwnAccount ? 1.0 : 0.6)
								.disabled(!store.canSelectOwnAccount)
								.padding(.horizontal, .medium3)
							} else {
								addressBookList
							}
						}
					}
					.background(.primaryBackground)
					.destinations(with: store)
					.footer { chooseButton }
					.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.navigationTitle) {
						store.send(.view(.closeButtonTapped))
					}
					.onAppear {
						store.send(.view(.appeared))
					}
				}
			}
		}

		@ViewBuilder
		private var addressBookList: some SwiftUI.View {
			if store.selectableAddressBookEntries.isEmpty {
				Text(L10n.AddressBook.emptyState)
					.textStyle(.body1HighImportance)
					.foregroundColor(.secondaryText)
					.multilineTextAlignment(.center)
					.padding(.medium3)
			} else {
				LazyVStack(spacing: .small2) {
					ForEachStatic(store.selectableAddressBookEntries) { entry in
						Button {
							store.send(.view(.addressBookEntrySelected(entry)))
						} label: {
							HStack {
								VStack(alignment: .leading, spacing: .small3) {
									Text(entry.name.value)
										.textStyle(.body1Header)
										.foregroundColor(.primaryText)
									AddressView(.address(.account(entry.address)))
										.foregroundColor(.secondaryText)
									if let note = entry.note, !note.isEmpty {
										Text(note)
											.textStyle(.body2Regular)
											.foregroundColor(.secondaryText)
											.multilineTextAlignment(.leading)
											.lineLimit(2)
									}
								}
								Spacer()
								RadioButton(
									appearance: colorScheme == .light ? .dark : .light,
									isSelected: false
								)
							}
							.frame(maxWidth: .infinity, alignment: .leading)
							.contentShape(Rectangle())
							.padding(.medium3)
						}
						.buttonStyle(.plain)
						.addressBookEntrySurface(interactive: true)
					}
				}
				.padding(.horizontal, .medium3)
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

		@ViewBuilder
		private var manualAddressBookStatus: some SwiftUI.View {
			if let entry = store.matchingAddressBookEntryForManualAddress {
				HStack {
					Text(L10n.AssetTransfer.ChooseReceivingAccount.savedAs(entry.name.value))
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)
					Spacer(minLength: .zero)
				}
				.padding(.horizontal, .small1)
			} else if store.canStoreValidatedManualRecipientInAddressBook {
				Button {
					store.send(.view(.storeManualRecipientInAddressBookToggled))
				} label: {
					HStack(spacing: .small2) {
						CheckmarkView(
							appearance: colorScheme == .light ? .dark : .light,
							isChecked: store.storeManualRecipientInAddressBook
						)
						Text(L10n.AssetTransfer.ChooseReceivingAccount.saveToAddressBook)
							.textStyle(.body2Regular)
							.foregroundColor(.primaryText)
						Spacer(minLength: .zero)
					}
				}
				.buttonStyle(.plain)
			}
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
		return scanQRCode(with: destinationStore)
			.addAddressBookEntry(with: destinationStore)
			.domainResolutionErrorAlert(with: destinationStore)
	}

	private func scanQRCode(with destinationStore: PresentationStoreOf<ChooseTransferRecipient.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.scanTransferRecipient, action: \.scanTransferRecipient)) {
			ScanQRCoordinator.View(store: $0)
				.radixToolbar(title: L10n.AssetTransfer.ChooseReceivingAccount.scanQRNavigationTitle, alwaysVisible: false)
		}
	}

	private func addAddressBookEntry(with destinationStore: PresentationStoreOf<ChooseTransferRecipient.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addAddressBookEntry, action: \.addAddressBookEntry)) {
			AddressBookEntryForm.View(store: $0)
		}
	}

	private func domainResolutionErrorAlert(with destinationStore: PresentationStoreOf<ChooseTransferRecipient.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.domainResolutionErrorAlert, action: \.domainResolutionErrorAlert))
	}
}
