import ChooseAccountsFeature
import FeaturePrelude
import ScanQRFeature

// MARK: - ChooseReceivingAccount
public struct ChooseReceivingAccount: Sendable, FeatureReducer {
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

		var validatedAccountAddress: AccountAddress? {
			if !manualAccountAddress.isEmpty,
			   !chooseAccounts.filteredAccounts.contains(where: { $0.address == manualAccountAddress })
			{
				return try? AccountAddress(validatingAddress: manualAccountAddress)
			}
			return nil
		}

		@PresentationState
		var destination: Destinations.State? = nil
	}

	public enum ViewAction: Sendable, Equatable {
		case scanQRCode
		case closeButtonTapped
		case manualAccountAddressChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(ReceivingAccount.State.Account)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case chooseAccounts(ChooseAccounts.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case handleResult(ReceivingAccount.State.Account)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case scanAccountAddress(ScanQRCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case scanAccountAddress(ScanQRCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.scanAccountAddress, action: /Action.scanAccountAddress) {
				ScanQRCoordinator()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.chooseAccounts, action: /Action.child .. ChildAction.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .scanQRCode:
			state.destination = .scanAccountAddress(.init(scanInstructions: L10n.AssetTransfer.qrScanInstructions))
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
			if case let .right(address) = result, let ownedAccount = state.chooseAccounts.availableAccounts.first(where: { $0.address == address }) {
				return .send(.delegate(.handleResult(.left(ownedAccount))))
			}
			return .send(.delegate(.handleResult(result)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case var .destination(.presented(.scanAccountAddress(.delegate(.scanned(address))))):
			state.destination = nil

			QR.removeAddressPrefixIfNeeded(from: &address)

			state.manualAccountAddress = address
			return .none
		default:
			return .none
		}
	}
}
