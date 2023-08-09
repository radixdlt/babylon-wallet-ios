import FeaturePrelude
import LedgerHardwareDevicesFeature

public struct AccountSecurity: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case mnemonicsButtonTapped
		case ledgerHardwareWalletsButtonTapped
		case importFromOlympiaWalletButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case mnemonics(DisplayMnemonics.State)
			case ledgerHardwareWallets(LedgerHardwareDevices.State)
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case mnemonics(DisplayMnemonics.Action)
			case ledgerHardwareWallets(LedgerHardwareDevices.Action)
			case importOlympiaWalletCoordinator(ImportOlympiaWalletCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.mnemonics, action: /Action.mnemonics) {
				DisplayMnemonics()
			}
			Scope(state: /State.ledgerHardwareWallets, action: /Action.ledgerHardwareWallets) {
				LedgerHardwareDevices()
			}
			Scope(state: /State.importOlympiaWalletCoordinator, action: /Action.importOlympiaWalletCoordinator) {
				ImportOlympiaWalletCoordinator()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .mnemonicsButtonTapped:
			state.destination = .mnemonics(.init())
			return .none

		case .ledgerHardwareWalletsButtonTapped:
			state.destination = .ledgerHardwareWallets(.init(context: .settings))
			return .none

		case .importFromOlympiaWalletButtonTapped:
			state.destination = .importOlympiaWalletCoordinator(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.importOlympiaWalletCoordinator(.delegate(.finishedMigration(gotoAccountList))))):
			state.destination = nil
			if gotoAccountList {
				// FIXME: Probably call delegate in order to dismiss all the way back
				return .run { _ in await dismiss() }
			}
			return .none

		case .destination:
			return .none
		}
	}
}
