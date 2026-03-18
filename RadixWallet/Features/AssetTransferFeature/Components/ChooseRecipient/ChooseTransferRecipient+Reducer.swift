import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseTransferRecipient
@Reducer
struct ChooseTransferRecipient: FeatureReducer {
	static let xrdDomainsHelp = URL(string: "https://docs.xrd.domains/#/wiki/records/namelets")!

	enum RecipientTab: Hashable {
		case myAccounts
		case addressBook
	}

	@ObservableState
	struct State: Hashable {
		var chooseAccounts: ChooseAccounts.State
		var manualTransferRecipient: String = "" {
			didSet {
				if !manualTransferRecipient.isEmpty {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}

		var sanitizedManualTransferRecipient: String {
			manualTransferRecipient.lowercased().trimmingWhitespacesAndNewlines()
		}

		var manualTransferRecipientFocused: Bool = false
		var isDeterminingRnsDomainRecipient: Bool = false
		var selectedTab: RecipientTab = .myAccounts
		var addressBookEntries: [AddressBookEntry] = []
		var storeManualRecipientInAddressBook: Bool = false
		var pendingExternalAccountAddressToSelect: AccountAddress?

		let networkID: NetworkID

		@Presents
		var destination: Destination.State? = nil

		init(networkID: NetworkID, chooseAccounts: ChooseAccounts.State) {
			self.networkID = networkID
			self.chooseAccounts = chooseAccounts
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case appeared
		case scanQRCode
		case closeButtonTapped
		case manualTransferRecipientChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(Either<Account, State.ManualTransferRecipient>)
		case tabChanged(RecipientTab)
		case addressBookEntrySelected(AddressBookEntry)
		case storeManualRecipientInAddressBookToggled
	}

	enum InternalAction: Equatable {
		case rnsDomainConfiguredRecieverResult(TaskResult<RnsDomainConfiguredReceiver>)
		case loadedAddressBookEntries([AddressBookEntry])
	}

	@CasePathable
	enum ChildAction: Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Equatable {
		case dismiss
		case handleResult(TransferRecipient)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case scanTransferRecipient(ScanQRCoordinator.State)
			case addAddressBookEntry(AddressBookEntryForm.State)
			case domainResolutionErrorAlert(AlertState<DomainResolutionErrorAlert>)
		}

		@CasePathable
		enum Action: Equatable {
			case scanTransferRecipient(ScanQRCoordinator.Action)
			case addAddressBookEntry(AddressBookEntryForm.Action)
			case domainResolutionErrorAlert(DomainResolutionErrorAlert)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.scanTransferRecipient, action: \.scanTransferRecipient) {
				ScanQRCoordinator()
			}
			Scope(state: \.addAddressBookEntry, action: \.addAddressBookEntry) {
				AddressBookEntryForm()
			}
		}
	}

	@Dependency(\.openURL) var openURL
	@Dependency(\.radixNameService) var radixNameService
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.addressBookClient) var addressBookClient

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let entries = ((try? addressBookClient.entriesOnCurrentNetwork()) ?? []).sortedForDisplay()
				await send(.internal(.loadedAddressBookEntries(entries)))
			}

		case .scanQRCode:
			state.destination = .scanTransferRecipient(.init(kind: .account))
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .manualTransferRecipientChanged(address):
			state.manualTransferRecipient = address
			if !state.canStoreValidatedManualRecipientInAddressBook {
				state.storeManualRecipientInAddressBook = false
			}
			return .none

		case let .focusChanged(isFocused):
			state.manualTransferRecipientFocused = isFocused
			return .none

		case let .chooseButtonTapped(result):
			switch result {
			case let .left(account):
				return .send(.delegate(.handleResult(.profileAccount(value: account.forDisplay))))
			case let .right(.accountAddress(address)):
				if state.storeManualRecipientInAddressBook,
				   state.canStoreValidatedManualRecipientInAddressBook,
				   state.validatedManualAccountAddress == address
				{
					state.pendingExternalAccountAddressToSelect = address
					state.destination = .addAddressBookEntry(.init(mode: .addWithAddress(address)))
					return .none
				}

				if let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == address }) {
					return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount.forDisplay))))
				} else {
					return .send(.delegate(.handleResult(.addressOfExternalAccount(value: address))))
				}
			case let .right(.rnsDomain(domain)):
				state.isDeterminingRnsDomainRecipient = true
				return .run { send in
					let result = await TaskResult {
						try await radixNameService.resolveReceiverAccountForDomain(domain)
					}
					return await send(.internal(.rnsDomainConfiguredRecieverResult(result)))
				}
			}

		case let .tabChanged(tab):
			state.selectedTab = tab
			return .none

		case let .addressBookEntrySelected(entry):
			return .send(.delegate(.handleResult(.addressOfExternalAccount(value: entry.address))))

		case .storeManualRecipientInAddressBookToggled:
			state.storeManualRecipientInAddressBook.toggle()
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedAddressBookEntries(entries):
			state.addressBookEntries = entries
			return .none

		case let .rnsDomainConfiguredRecieverResult(.success(recipient)):
			state.isDeterminingRnsDomainRecipient = false
			if let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == recipient.receiver }) {
				return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount.forDisplay))))
			}
			return .send(.delegate(.handleResult(.rnsDomain(value: recipient))))

		case let .rnsDomainConfiguredRecieverResult(.failure(error)):
			state.isDeterminingRnsDomainRecipient = false
			switch error as? CommonError {
			case CommonError.GwMissingResponseItem?:
				state.destination = .domainResolutionErrorAlert(.domainResolutionErrorAlert)
				return .none
			default:
				errorQueue.schedule(DomainResolutionError(error: error))
				return .none
			}
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case var .scanTransferRecipient(.delegate(.scanned(address))):
			state.destination = nil

			QR.removeTransferRecipientPrefixIfNeeded(from: &address)

			state.manualTransferRecipient = address
			return .none

		case .domainResolutionErrorAlert(.visitXrdDomain):
			return .run { _ in
				await openURL(Self.xrdDomainsHelp)
			}

		case .addAddressBookEntry(.delegate(.saved)):
			guard let address = state.pendingExternalAccountAddressToSelect else {
				state.destination = nil
				return .none
			}
			state.pendingExternalAccountAddressToSelect = nil
			state.destination = nil
			return .send(.delegate(.handleResult(.addressOfExternalAccount(value: address))))

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		state.pendingExternalAccountAddressToSelect = nil
		return .none
	}
}

// MARK: - DomainResolutionError
struct DomainResolutionError: LocalizedError {
	let error: Swift.Error

	var errorDescription: String? {
		switch error as? CommonError {
		case CommonError.GwMissingResponseItem?,
		     CommonError.RnsUnauthenticDomain?,
		     CommonError.RnsInvalidRecordContext?,
		     CommonError.RnsInvalidDomainConfiguration?:
			L10n.Error.Rns.unknownDomain
		case CommonError.RnsUnsupportedNetwork?:
			L10n.Error.TransactionFailure.network
		default:
			L10n.TransactionStatus.Failure.title
		}
	}
}

extension String {
	var isRnsDomain: Bool {
		self.hasSuffix(".xrd")
	}
}

// MARK: - DomainResolutionErrorAlert
enum DomainResolutionErrorAlert: Hashable {
	case okTapped
	case visitXrdDomain
}

extension AlertState<DomainResolutionErrorAlert> {
	static var domainResolutionErrorAlert: AlertState {
		AlertState {
			TextState(L10n.Common.errorAlertTitle)
		} actions: {
			ButtonState(role: .cancel, action: .okTapped) {
				TextState(L10n.Common.ok)
			}
			ButtonState(action: .visitXrdDomain) {
				TextState(L10n.Error.Rns.unknownDomainButtonTitle)
			}
		} message: {
			TextState(L10n.Error.Rns.unknownDomain)
		}
	}
}
