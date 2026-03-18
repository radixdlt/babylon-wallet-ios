import ComposableArchitecture
import Sargon

// MARK: - AddressBookEntryForm
@Reducer
struct AddressBookEntryForm: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		enum Mode: Hashable {
			case add
			case addWithAddress(AccountAddress)
			case edit(AddressBookEntry)
		}

		let mode: Mode
		var address: String
		var name: String
		var note: String

		@Presents
		var destination: Destination.State? = nil

		init(mode: Mode) {
			self.mode = mode
			switch mode {
			case .add:
				self.address = ""
				self.name = ""
				self.note = ""
			case let .addWithAddress(address):
				self.address = address.address
				self.name = ""
				self.note = ""
			case let .edit(entry):
				self.address = entry.address.address
				self.name = entry.name.value
				self.note = entry.note ?? ""
			}
		}

		var validatedAddress: AccountAddress? {
			try? AccountAddress(validatingAddress: address.trimmingWhitespacesAndNewlines())
		}

		var addressToSave: AccountAddress? {
			switch mode {
			case .add:
				validatedAddress
			case let .addWithAddress(address):
				address
			case let .edit(entry):
				entry.address
			}
		}

		var isAddressEditable: Bool {
			switch mode {
			case .add:
				true
			case .addWithAddress, .edit:
				false
			}
		}

		var trimmedName: String {
			name.trimmingWhitespacesAndNewlines()
		}

		var trimmedNote: String? {
			let trimmedNote = note.trimmingWhitespacesAndNewlines()
			return trimmedNote.isEmpty ? nil : trimmedNote
		}

		var isValid: Bool {
			addressToSave != nil && !trimmedName.isEmpty
		}

		var addressHint: Hint.ViewState? {
			guard !address.isEmpty, validatedAddress == nil else { return nil }
			return .error(L10n.AddressBook.EntryForm.invalidAddress)
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case addressChanged(String)
		case nameChanged(String)
		case noteChanged(String)
		case scanQRCodeTapped
		case saveButtonTapped
		case cancelButtonTapped
	}

	enum InternalAction: Equatable {
		case ownAccountAddressNotAllowed
	}

	enum DelegateAction: Equatable {
		case saved
	}

	@Dependency(\.addressBookClient) var addressBookClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case scanQR(ScanQRCoordinator.State)
			case ownAccountAddressNotAllowedAlert(AlertState<OwnAccountAddressNotAllowedAlert>)
		}

		@CasePathable
		enum Action: Equatable {
			case scanQR(ScanQRCoordinator.Action)
			case ownAccountAddressNotAllowedAlert(OwnAccountAddressNotAllowedAlert)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.scanQR, action: \.scanQR) {
				ScanQRCoordinator()
			}
		}

		enum OwnAccountAddressNotAllowedAlert: Hashable {
			case okTapped
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .ownAccountAddressNotAllowed:
			state.destination = .ownAccountAddressNotAllowedAlert(.ownAccountAddressNotAllowedAlert)
			return .none
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .addressChanged(value):
			state.address = value
			return .none

		case let .nameChanged(value):
			state.name = value
			return .none

		case let .noteChanged(value):
			state.note = value
			return .none

		case .scanQRCodeTapped:
			state.destination = .scanQR(.init(kind: .account))
			return .none

		case .saveButtonTapped:
			guard let address = state.addressToSave else { return .none }
			let name = DisplayName(value: state.trimmedName)
			let note = state.trimmedNote
			let mode = state.mode
			return .run { send in
				let shouldRejectOwnedAddress = switch mode {
				case .add, .addWithAddress:
					true
				case .edit:
					false
				}

				if shouldRejectOwnedAddress {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					if accounts.contains(where: { $0.address == address }) {
						await send(.internal(.ownAccountAddressNotAllowed))
						return
					}
				}

				switch mode {
				case .add, .addWithAddress:
					_ = try await addressBookClient.addEntry(address, name, note)
				case .edit:
					_ = try await addressBookClient.updateEntry(address, name, note)
				}
				await send(.delegate(.saved))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .cancelButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .scanQR(.delegate(.scanned(address))):
			var scannedAddress = address
			QR.removeTransferRecipientPrefixIfNeeded(from: &scannedAddress)
			state.address = scannedAddress
			state.destination = nil
			return .none

		case .scanQR(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case .ownAccountAddressNotAllowedAlert(.okTapped):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

private extension AlertState where Action == AddressBookEntryForm.Destination.OwnAccountAddressNotAllowedAlert {
	static var ownAccountAddressNotAllowedAlert: AlertState {
		AlertState {
			TextState(L10n.AddressBook.EntryForm.ownAccountAlertTitle)
		} actions: {
			ButtonState(role: .cancel, action: .okTapped) {
				TextState(L10n.Common.ok)
			}
		} message: {
			TextState(L10n.AddressBook.EntryForm.ownAccountAlertMessage)
		}
	}
}
