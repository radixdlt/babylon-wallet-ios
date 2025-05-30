import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccount
@Reducer
struct ChooseTransferReceiver: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var manualTransferReceiver: String = "" {
			didSet {
				if !manualTransferReceiver.isEmpty {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}

		var manualTransferReceiverFocused: Bool = false

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
	enum ViewAction: Sendable, Equatable {
		case scanQRCode
		case closeButtonTapped
		case manualTransferReceiverChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(AccountOrAddressOf)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case handleResult(AccountOrAddressOf)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.scanAccountAddress, action: \.scanAccountAddress) {
				ScanQRCoordinator()
			}
		}
	}

	init() {}

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
		case .scanQRCode:
			state.destination = .scanAccountAddress(.init(kind: .account))
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .manualTransferReceiverChanged(address):
			state.manualTransferReceiver = address
			return .none

		case let .focusChanged(isFocused):
			state.manualTransferReceiverFocused = isFocused
			return .none

		case let .chooseButtonTapped(result):
			// While we allow to easily selected the owned account, user is still able to paste the address of an owned account.
			// This be sure to check if the manually introduced address matches any of the user owned accounts.
			if case let .addressOfExternalAccount(address) = result, let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == address }) {
				return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount.forDisplay))))
			}
			return .send(.delegate(.handleResult(result)))
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case var .scanAccountAddress(.delegate(.scanned(address))):
			state.destination = nil

			QR.removeAddressPrefixIfNeeded(from: &address)

			state.manualTransferReceiver = address
			return .none

		default:
			return .none
		}
	}
}
