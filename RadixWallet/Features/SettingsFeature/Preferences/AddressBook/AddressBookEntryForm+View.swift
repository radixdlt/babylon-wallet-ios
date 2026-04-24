import ComposableArchitecture
import SwiftUI

// MARK: - AddressBookEntryForm.View
extension AddressBookEntryForm {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<AddressBookEntryForm>

		init(store: StoreOf<AddressBookEntryForm>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .medium2) {
							addressSection

							AppTextField(
								placeholder: L10n.AddressBook.EntryForm.namePlaceholder,
								text: $store.name.sending(\.view.nameChanged)
							)

							AppTextField(
								placeholder: L10n.AddressBook.EntryForm.notePlaceholder,
								text: $store.note.sending(\.view.noteChanged)
							)
						}
						.padding(.medium3)
					}
					.background(.primaryBackground)
					.radixToolbar(title: isEditing ? L10n.AddressBook.EntryForm.editTitle : L10n.AddressBook.EntryForm.addTitle) {
						store.send(.view(.cancelButtonTapped))
					}
					.destinations(with: store)
					.footer {
						Button(L10n.Common.save) {
							store.send(.view(.saveButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.disabled(!store.isValid)
					}
				}
			}
		}

		private var isEditing: Bool {
			if case .edit = store.mode { return true }
			return false
		}

		@ViewBuilder
		private var addressSection: some SwiftUI.View {
			if !store.isAddressEditable {
				if let address = store.addressToSave {
					HStack {
						if let identifiableAddress = LedgerIdentifiable.Address(address: address) {
							AddressView(.address(identifiableAddress))
								.foregroundColor(.secondaryText)
						} else {
							Text(address.formatted(.default))
								.textStyle(.body1Regular)
								.foregroundColor(.secondaryText)
								.lineLimit(1)
						}
						Spacer(minLength: .zero)
					}
					.padding(.horizontal, .small1)
				}
			} else {
				AppTextField(
					placeholder: L10n.AddressBook.EntryForm.addressPlaceholder,
					text: $store.address.sending(\.view.addressChanged),
					hint: store.addressHint,
					innerAccessory: {
						Button(asset: AssetResource.qrCodeScanner) {
							store.send(.view(.scanQRCodeTapped))
						}
					}
				)
				.autocorrectionDisabled()
				.textInputAutocapitalization(.never)
				.keyboardType(.alphabet)
			}
		}
	}
}

private extension StoreOf<AddressBookEntryForm> {
	var destination: PresentationStoreOf<AddressBookEntryForm.Destination> {
		func scopeState(state: State) -> PresentationState<AddressBookEntryForm.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AddressBookEntryForm>) -> some View {
		let destinationStore = store.destination
		return scanQRCode(with: destinationStore)
			.ownAccountAddressNotAllowedAlert(with: destinationStore)
	}

	private func scanQRCode(with destinationStore: PresentationStoreOf<AddressBookEntryForm.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.scanQR, action: \.scanQR)) {
			ScanQRCoordinator.View(store: $0)
		}
	}

	private func ownAccountAddressNotAllowedAlert(with destinationStore: PresentationStoreOf<AddressBookEntryForm.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.ownAccountAddressNotAllowedAlert, action: \.ownAccountAddressNotAllowedAlert))
	}
}
