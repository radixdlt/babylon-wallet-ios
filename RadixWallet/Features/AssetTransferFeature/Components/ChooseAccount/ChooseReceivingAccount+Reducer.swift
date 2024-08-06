import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseReceivingAccount
@Reducer
public struct ChooseReceivingAccount: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var manualAccountAddress: String = "" {
			didSet {
				if !manualAccountAddress.isEmpty {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}

		var manualAccountAddressFocused: Bool = false

		let networkID: NetworkID

		@Presents
		var destination: Destination.State? = nil

		public init(networkID: NetworkID, chooseAccounts: ChooseAccounts.State) {
			self.networkID = networkID
			self.chooseAccounts = chooseAccounts
		}
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case scanQRCode
		case closeButtonTapped
		case manualAccountAddressChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(AccountOrAddressOf)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case handleResult(AccountOrAddressOf)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.scanAccountAddress, action: \.scanAccountAddress) {
				ScanQRCoordinator()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .scanQRCode:
			state.destination = .scanAccountAddress(.init(kind: .account))
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .manualAccountAddressChanged(address):
			state.manualAccountAddress = address
			return .none

		case let .focusChanged(isFocused):
			state.manualAccountAddressFocused = isFocused
			return .none

		case let .chooseButtonTapped(result):
			// While we allow to easily selected the owned account, user is still able to paste the address of an owned account.
			// This be sure to check if the manually introduced address matches any of the user owned accounts.
			if case let .addressOfExternalAccount(address) = result, let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == address }) {
				return .send(.delegate(.handleResult(.profileAccount(value: ownedAccount))))
			}
			return .send(.delegate(.handleResult(result)))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case var .scanAccountAddress(.delegate(.scanned(address))):
			state.destination = nil

			QR.removeAddressPrefixIfNeeded(from: &address)

			state.manualAccountAddress = address
			return .none

		default:
			return .none
		}
	}
}
