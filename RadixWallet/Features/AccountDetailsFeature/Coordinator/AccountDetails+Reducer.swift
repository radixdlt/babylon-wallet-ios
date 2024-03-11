import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails
public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, AccountWithInfoHolder {
		public var accountWithInfo: AccountWithInfo
		var assets: AssetsView.State

		@PresentationState
		var destination: Destination.State?

		public init(
			accountWithInfo: AccountWithInfo
		) {
			self.accountWithInfo = accountWithInfo
			self.assets = AssetsView.State(
				account: accountWithInfo.account,
				mode: .normal
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case backButtonTapped
		case preferencesButtonTapped
		case transferButtonTapped
		case historyButtonTapped

		case exportMnemonicButtonTapped
		case importMnemonicButtonTapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
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

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case preferences(AccountPreferences.State)
			case history(TransactionHistory.State)
			case transfer(AssetTransfer.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case preferences(AccountPreferences.Action)
			case history(TransactionHistory.Action)
			case transfer(AssetTransfer.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: \.preferences, action: \.preferences) {
				AccountPreferences()
			}
			Scope(state: \.history, action: \.history) {
				TransactionHistory()
			}
			Scope(state: \.transfer, action: \.transfer) {
				AssetTransfer()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.openURL) var openURL

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.assets, action: /Action.child .. ChildAction.assets) {
			AssetsView()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

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

		case .historyButtonTapped:

			//		let mockAccount = state.account.networkID == .mainnet ? try! AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l") : nil

//			func loadResources(state: State) -> Effect<Action> {
//				.run { [account = state.account.address] send in
//					let resources = try await accountPortfoliosClient.fetchAccountPortfolio(account, false).allResources
//					await send(.internal(.loadedResources(resources)))
//				}
//			}

			do {
				state.destination = try .history(.init(account: state.account))
			} catch {
				errorQueue.schedule(error)
			}

			return .none

		case .exportMnemonicButtonTapped:
			return .send(.delegate(.exportMnemonic(controlling: state.account)))

		case .importMnemonicButtonTapped:
			return .send(.delegate(.importMnemonics))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .assets(.internal(.resourcesUpdated)):
			checkAccountAccessToMnemonic(state: &state)
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(account):
			state.account = account
			checkAccountAccessToMnemonic(state: &state)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .transfer(.delegate(.dismissed)):
			state.destination = nil
			return .none

		case .preferences(.delegate(.accountHidden)):
			return .send(.delegate(.dismiss))

		default:
			return .none
		}
	}

	private func checkAccountAccessToMnemonic(state: inout State) {
		let xrdResource = state.assets.fungibleTokenList?.sections[id: .xrd]?.rows.first?.token
		state.checkAccountAccessToMnemonic(xrdResource: xrdResource)
	}
}
