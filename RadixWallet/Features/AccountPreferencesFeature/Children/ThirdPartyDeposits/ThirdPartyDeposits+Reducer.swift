import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ManageThirdPartyDeposits
public struct ManageThirdPartyDeposits: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var account: Sargon.Account

		var depositRule: DepositRule {
			thirdPartyDeposits.depositRule
		}

		var thirdPartyDeposits: ThirdPartyDeposits

		@PresentationState
		var destination: Destination.State? = nil

		init(account: Sargon.Account) {
			self.account = account
			self.thirdPartyDeposits = account.onLedgerSettings.thirdPartyDeposits
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case updateTapped
		case rowTapped(ManageThirdPartyDeposits.Section.Row)
	}

	public enum DelegateAction: Equatable, Sendable {
		case accountUpdated
	}

	public enum InternalAction: Equatable, Sendable {
		case updated(Sargon.Account)
	}

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case allowDenyAssets(ResourcesList.State)
			case allowDepositors(ResourcesList.State)
		}

		public enum Action: Equatable, Sendable {
			case allowDenyAssets(ResourcesList.Action)
			case allowDepositors(ResourcesList.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.allowDenyAssets, action: /Action.allowDenyAssets) {
				ResourcesList()
			}

			Scope(state: /State.allowDepositors, action: /Action.allowDepositors) {
				ResourcesList()
			}
		}
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .rowTapped(row):
			switch row {
			case let .depositRule(rule):
				state.thirdPartyDeposits.depositRule = rule

			case .allowDenyAssets:
				state.destination = .allowDenyAssets(.init(
					canModify: !state.thirdPartyDeposits.isAssetsExceptionsUnknown,
					mode: .allowDenyAssets(.allow),
					thirdPartyDeposits: state.thirdPartyDeposits,
					networkID: state.account.networkID
				))

			case .allowDepositors:
				state.destination = .allowDepositors(.init(
					canModify: !state.thirdPartyDeposits.isAllowedDepositorsUnknown,
					mode: .allowDepositors,
					thirdPartyDeposits: state.thirdPartyDeposits,
					networkID: state.account.networkID
				))
			}
			return .none
		case .updateTapped:
			do {
				let (manifest, updatedAccount) = try prepareForSubmission(state)
				return submitTransaction(manifest, updatedAccount: updatedAccount)
			} catch {
				errorQueue.schedule(error)
				return .none
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updated(account):
			state.account = account
			state.thirdPartyDeposits = account.onLedgerSettings.thirdPartyDeposits
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .allowDenyAssets(.delegate(.updated(thirdPartyDeposits))),
		     let .allowDepositors(.delegate(.updated(thirdPartyDeposits))):
			state.thirdPartyDeposits = thirdPartyDeposits
			return .none
		default:
			return .none
		}
	}

	private func submitTransaction(_ manifest: TransactionManifest, updatedAccount: Sargon.Account) -> Effect<Action> {
		.run { send in
			do {
				/// Wait for user to complete the interaction with Transaction Review
				let result = try await dappInteractionClient.addWalletInteraction(
					.transaction(.init(send: .init(transactionManifest: manifest))),
					.accountDepositSettings
				)

				switch result {
				case let .dapp(.success(success)):
					if case let .transaction(tx) = success.items {
						/// Wait for the transaction to be committed
						let txID = tx.send.transactionIntentHash
						try await submitTXClient.hasTXBeenCommittedSuccessfully(txID)
						/// Safe to update the account to new state
						try await accountsClient.updateAccount(updatedAccount)
						await send(.internal(.updated(updatedAccount)))
						return
					}

					assertionFailure("Not a transaction Response?")
				case .dapp(.failure), .none:
					/// Either user did dismiss the TransctionReview, or there was a failure.
					/// Any failure message will be displayed in Transaction Review
					break
				}

			} catch {
				/// Polling failure will be displayed in SubmiTransactionView
				if case is TXFailureStatus = error {
					return
				}
				errorQueue.schedule(error)
			}
		}
	}

	private func prepareForSubmission(
		_ state: State
	) throws -> (
		manifest: TransactionManifest,
		account: Sargon.Account
	) {
		let inProfileConfig = state.account.onLedgerSettings.thirdPartyDeposits
		let localConfig = state.thirdPartyDeposits
		var updatedAccount = state.account
		updatedAccount.onLedgerSettings.thirdPartyDeposits = localConfig
		return (
			manifest: TransactionManifest.thirdPartyDepositUpdate(
				accountAddress: state.account.accountAddress,
				from: inProfileConfig.intoSargon(),
				to: localConfig.intoSargon()
			),
			account: updatedAccount
		)
	}
}
