import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails
public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var account: Profile.Network.Account
		var assets: AssetsView.State

		public var isShowingImportMnemonicPrompt: Bool
		public var isShowingExportMnemonicPrompt: Bool

		@PresentationState
		var destination: Destinations.State?

		fileprivate var deviceControlledFactorInstance: HierarchicalDeterministicFactorInstance {
			switch account.securityState {
			case let .unsecured(control):
				control.transactionSigning
			}
		}

		public init(
			for account: Profile.Network.Account,
			isShowingImportMnemonicPrompt: Bool = false,
			isShowingExportMnemonicPrompt: Bool = false
		) {
			self.account = account
			self.assets = AssetsView.State(account: account, mode: .normal)
			self.isShowingImportMnemonicPrompt = isShowingImportMnemonicPrompt
			self.isShowingExportMnemonicPrompt = isShowingExportMnemonicPrompt
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case backButtonTapped
		case preferencesButtonTapped
		case transferButtonTapped

		case exportMnemonicButtonTapped
		case recoverMnemonicsButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case exportMnemonic(controlling: Profile.Network.Account)
		case importMnemonics
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Profile.Network.Account)
	}

	public struct MnemonicWithPassphraseAndFactorSourceInfo: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public let factorSourceKind: FactorSourceKind
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case preferences(AccountPreferences.State)
			case transfer(AssetTransfer.State)
		}

		public enum Action: Sendable, Equatable {
			case preferences(AccountPreferences.Action)
			case transfer(AssetTransfer.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.preferences, action: /Action.preferences) {
				AccountPreferences()
			}
			Scope(state: /State.transfer, action: /Action.transfer) {
				AssetTransfer()
			}
		}
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.assets, action: /Action.child .. ChildAction.assets) {
			AssetsView()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [state] send in
				for try await accountUpdate in await accountsClient.accountUpdates(state.account.address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}

		case .backButtonTapped:
			return .send(.delegate(.dismiss))

		case .preferencesButtonTapped:
			state.destination = .preferences(.init(account: state.account))
			return .none

		case .transferButtonTapped:
			state.destination = .transfer(.init(
				from: state.account
			))
			return .none

		case .exportMnemonicButtonTapped:
			return .send(.delegate(.exportMnemonic(controlling: state.account)))

		case .recoverMnemonicsButtonTapped:
			return .send(.delegate(.importMnemonics))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .destination(.presented(.transfer(.delegate(.dismissed)))):
			state.destination = nil
			return .none

		case let .assets(.delegate(.xrdBalanceUpdated(xrdBalance))):
//			return checkIfShouldShowExportMnemonicPrompt(state: &state)
			// return .send(.delegate(.))
			fatalError()

		case .destination(.presented(.preferences(.delegate(.accountHidden)))):
			return .send(.delegate(.dismiss))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(account):
			state.account = account
			return .none
		}
	}

//	private func checkIfShouldShowExportMnemonicPrompt(state: inout State) -> Effect<Action> {
//		guard !state.isShowingImportMnemonicPrompt else {
//			return .none
//		}
//
//		@Dependency(\.userDefaultsClient) var userDefaultsClient
//
//		let mightNeedToBeBackedUp: Bool = {
//			guard let deviceFactorSourceID = state.account.deviceFactorSourceID else {
//				// Ledger account, mnemonics do not apply...
//				return false
//			}
//			// check if already backed up
//			let isAlreadyBackedUp = userDefaultsClient
//				.getFactorSourceIDOfBackedUpMnemonics()
//				.contains(deviceFactorSourceID)
//
//			return !isAlreadyBackedUp
//		}()
//
//		guard mightNeedToBeBackedUp else {
//			return .none
//		}
//
//		guard let xrdOwned = state.assets.fungibleTokenList?.sections[id: .xrd]?.rows.first else {
//			return .none
//		}
//
//		assert(xrdOwned.isXRD)
//
//		guard xrdOwned.token.amount > .zero else {
//			return .none
//		}
//
//		return .send(.internal(.markBackupNeeded))
//	}
}
