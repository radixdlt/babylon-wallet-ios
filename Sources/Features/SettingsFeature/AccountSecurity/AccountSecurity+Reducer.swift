import AppPreferencesClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareDevicesFeature

public struct AccountSecurity: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State? = nil
		public var preferences: AppPreferences? = nil
		public var hasLedgerHardwareWalletFactorSources: Bool = false

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case mnemonicsButtonTapped
		case defaultDepositGuaranteeButtonTapped
		case ledgerHardwareWalletsButtonTapped
		case useVerboseModeToggled(Bool)
		case importFromOlympiaWalletButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
		case hasLedgerHardwareWalletFactorSourcesLoaded(Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case mnemonics(DisplayMnemonics.State)
			case ledgerHardwareWallets(LedgerHardwareDevices.State)
			case depositGuarantees(DefaultDepositGuarantees.State)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case mnemonics(DisplayMnemonics.Action)
			case ledgerHardwareWallets(LedgerHardwareDevices.Action)
			case depositGuarantees(DefaultDepositGuarantees.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.mnemonics, action: /Action.mnemonics) {
				DisplayMnemonics()
			}
			Scope(state: /State.ledgerHardwareWallets, action: /Action.ledgerHardwareWallets) {
				LedgerHardwareDevices()
			}
			Scope(state: /State.depositGuarantees, action: /Action.depositGuarantees) {
				DefaultDepositGuarantees()
			}
			Scope(state: /State.importOlympiaWallet, action: /Action.importOlympiaWallet) {
				ImportOlympiaWalletCoordinator()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let preferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadPreferences(preferences)))

				do {
					let ledgers = try await factorSourcesClient.getFactorSources(type: LedgerHardwareWalletFactorSource.self)
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(!ledgers.isEmpty)))
				} catch {
					loggerGlobal.warning("Failed to load ledgers, error: \(error)")
					// OK to display it...
					await send(.internal(.hasLedgerHardwareWalletFactorSourcesLoaded(true)))
				}
			}

		case .mnemonicsButtonTapped:
			state.destination = .mnemonics(.init())
			return .none

		case .ledgerHardwareWalletsButtonTapped:
			state.destination = .ledgerHardwareWallets(.init(context: .settings))
			return .none

		case .defaultDepositGuaranteeButtonTapped:
			state.destination = .depositGuarantees(.init())
			return .none

		case let .useVerboseModeToggled(useVerboseMode):
			state.preferences?.display.ledgerHQHardwareWalletSigningDisplayMode = useVerboseMode ? .verbose : .summary
			guard let preferences = state.preferences else { return .none }
			return .fireAndForget {
				try await appPreferencesClient.updatePreferences(preferences)
			}

		case .importFromOlympiaWalletButtonTapped:
			state.destination = .importOlympiaWallet(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none

		case let .hasLedgerHardwareWalletFactorSourcesLoaded(hasLedgerHardwareWalletFactorSources):
			state.hasLedgerHardwareWalletFactorSources = hasLedgerHardwareWalletFactorSources
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.importOlympiaWallet(.delegate(.finishedMigration(gotoAccountList))))):
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
