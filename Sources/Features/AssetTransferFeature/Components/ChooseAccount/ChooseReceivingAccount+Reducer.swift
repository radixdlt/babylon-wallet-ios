import ChooseAccounts
import EngineToolkitClient
import FeaturePrelude
import ScanQRFeature

// MARK: - ChooseReceivingAccount
public struct ChooseReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var chooseAccounts: ChooseAccounts.State
		var manualAccountAddress: String = ""
		var manualAccountAddressFocused: Bool = false {
			didSet {
				if manualAccountAddressFocused {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}

		var validatedAccountAddress: AccountAddress? {
			if !manualAccountAddressFocused, !manualAccountAddress.isEmpty {
				do {
					return try AccountAddress(address: manualAccountAddress)
				} catch {
					return nil
				}
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

	@Dependency(\.engineToolkitClient) var engineToolkitClient

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
			state.destination = .scanAccountAddress(.init(scanInstructions: "Scan a QR code of a Radix account address"))
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
			return .send(.delegate(.handleResult(result)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case var .destination(.presented(.scanAccountAddress(.delegate(.scanned(address))))):
			state.destination = nil

			// FIXME: We should have a predefined way to handle the qr address prefix
			let prefix = "radix:"
			if address.hasPrefix(prefix) {
				address.removeFirst(prefix.count)
			}

			state.manualAccountAddress = address
			return .none
		default:
			return .none
		}
	}
}
