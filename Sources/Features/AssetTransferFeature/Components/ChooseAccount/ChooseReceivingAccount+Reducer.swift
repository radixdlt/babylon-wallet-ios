import ChooseAccounts
import EngineToolkitClient
import FeaturePrelude
import ScanQRFeature

// MARK: - ChooseReceivingAccount
public struct ChooseReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destinations.State? = nil
		var chooseAccounts: ChooseAccounts.State

		var manualAccountAddress: String = ""
		var manualAccountAddressFocused: Bool = false {
			didSet {
				if manualAccountAddressFocused {
					chooseAccounts.selectedAccounts = nil
				}
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case scanQRCode
		case closeButtonTapped
		case manualAccountAddressChanged(String)
		case focusChanged(Bool)
		case chooseButtonTapped(Either<Profile.Network.Account, AccountAddress>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case chooseAccounts(ChooseAccounts.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case handleResult(Either<Profile.Network.Account, AccountAddress>)
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
		case let .destination(.presented(.scanAccountAddress(.delegate(.scanned(address))))):
			state.destination = nil

			let prefix = "radix:"
			var address = address

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

extension DecodeAddressResponse {
	var isAccountAddress: Bool {
		switch entityType {
		case .accountComponent, .ed25519VirtualAccountComponent, .secp256k1VirtualAccountComponent:
			return true
		default:
			return false
		}
	}
}
