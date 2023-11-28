import ComposableArchitecture
import SwiftUI

// MARK: - AccountSecurity
public struct AccountSecurity: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State? = nil
		public var preferences: AppPreferences? = nil

		public var canImportOlympiaWallet = false

		public static let importOlympia = Self(destination: .importOlympiaWallet(.init()))

		public init(destination: Destination.State? = nil) {
			self.destination = destination
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case mnemonicsButtonTapped
		case defaultDepositGuaranteeButtonTapped
		case ledgerHardwareWalletsButtonTapped
		case importFromOlympiaWalletButtonTapped
		case accountRecoveryButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadPreferences(AppPreferences)
		case canImportOlympiaAccountResult(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case mnemonics(DisplayMnemonics.State)
			case ledgerHardwareWallets(LedgerHardwareDevices.State)
			case depositGuarantees(DefaultDepositGuarantees.State)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.State)
			case accountRecovery(ManualAccountRecovery.State)
		}

		public enum Action: Sendable, Equatable {
			case mnemonics(DisplayMnemonics.Action)
			case ledgerHardwareWallets(LedgerHardwareDevices.Action)
			case depositGuarantees(DefaultDepositGuarantees.Action)
			case importOlympiaWallet(ImportOlympiaWalletCoordinator.Action)
			case accountRecovery(ManualAccountRecovery.Action)
		}

		public var body: some ReducerOf<Self> {
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
			Scope(state: /State.accountRecovery, action: /Action.accountRecovery) {
				ManualAccountRecovery()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let preferences = await appPreferencesClient.getPreferences()
				await send(.internal(.loadPreferences(preferences)))

				let currentNetworkID = await factorSourcesClient.getCurrentNetworkID()

				// we only allow import SwiftUI
				let canImportOlympiaAccount = currentNetworkID == .mainnet

				await send(.internal(
					.canImportOlympiaAccountResult(canImportOlympiaAccount)
				))
			}

		case .mnemonicsButtonTapped:
			state.destination = .mnemonics(.init())
			return .none

		case .ledgerHardwareWalletsButtonTapped:
			state.destination = .ledgerHardwareWallets(.init(context: .settings))
			return .none

		case .defaultDepositGuaranteeButtonTapped:
			let depositGuarantee = state.preferences?.transaction.defaultDepositGuarantee ?? 1
			state.destination = .depositGuarantees(.init(depositGuarantee: depositGuarantee))
			return .none

		case .importFromOlympiaWalletButtonTapped:
			state.destination = .importOlympiaWallet(.init())
			return .none

		case .accountRecoveryButtonTapped:
			state.destination = .accountRecovery(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadPreferences(preferences):
			state.preferences = preferences
			return .none
		case let .canImportOlympiaAccountResult(canImportOlympiaWallet):
			state.canImportOlympiaWallet = canImportOlympiaWallet
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .accountRecovery(.delegate(.gotoAccountList)):
			return .send(.delegate(.gotoAccountList))

		case let .importOlympiaWallet(.delegate(.finishedMigration(gotoAccountList))):
			if gotoAccountList {
				return .send(.delegate(.gotoAccountList))
			} else {
				state.destination = nil
				return .none
			}

		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		if case let .depositGuarantees(depositGuarantees) = state.destination, let value = depositGuarantees.depositGuarantee {
			state.preferences?.transaction.defaultDepositGuarantee = value
			return savePreferences(state: state)
		}
		return .none
	}

	private func savePreferences(state: State) -> Effect<Action> {
		guard let preferences = state.preferences else { return .none }
		return .run { _ in
			try await appPreferencesClient.updatePreferences(preferences)
		}
	}
}
