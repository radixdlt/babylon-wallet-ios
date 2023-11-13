import ComposableArchitecture
import SwiftUI
public typealias ThirdPartyDeposits = Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits

// MARK: - ManageThirdPartyDeposits
public struct ManageThirdPartyDeposits: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account

		var depositRule: ThirdPartyDeposits.DepositRule {
			thirdPartyDeposits.depositRule
		}

		var thirdPartyDeposits: ThirdPartyDeposits

		@PresentationState
		var destination: Destination.State? = nil

		init(account: Profile.Network.Account) {
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
		case updated(Profile.Network.Account)
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
			.ifLet(\.$destination, action: /Action.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .rowTapped(row):
			switch row {
			case let .depositRule(rule):
				state.thirdPartyDeposits.depositRule = rule

			case .allowDenyAssets:
				state.destination = .allowDenyAssets(.init(
					mode: .allowDenyAssets(.allow),
					thirdPartyDeposits: state.thirdPartyDeposits,
					networkID: state.account.networkID
				))

			case .allowDepositors:
				state.destination = .allowDepositors(.init(
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

	private func submitTransaction(_ manifest: TransactionManifest, updatedAccount: Profile.Network.Account) -> Effect<Action> {
		.run { send in
			do {
				/// Wait for user to complete the interaction with Transaction Review
				let result = await dappInteractionClient.addWalletInteraction(
					.transaction(
						.init(
							send: .init(
								version: .default,
								transactionManifest: manifest,
								message: nil
							))
					),
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

	private func prepareForSubmission(_ state: State) throws -> (manifest: TransactionManifest, account: Profile.Network.Account) {
		let inProfileConfig = state.account.onLedgerSettings.thirdPartyDeposits
		let localConfig = state.thirdPartyDeposits

		// 1. Deposit rule change:
		let depositorRuleChange: ThirdPartyDeposits.DepositRule? = inProfileConfig.depositRule != localConfig.depositRule ? localConfig.depositRule : nil

		// 2. assetException changes:
		let assetExceptionsToAddOrUpdate: [ThirdPartyDeposits.AssetException] = localConfig
			.assetsExceptionList
			.filter { localException in
				!inProfileConfig.assetsExceptionList.contains { inProfileException in
					inProfileException.exceptionRule == localException.exceptionRule
				}
			}

		let assetExceptionsToBeRemoved: [ResourceAddress] = inProfileConfig
			.assetsExceptionList
			.filter {
				!localConfig.assetsExceptionList.contains($0)
			}
			.map(\.address)

		// 3. Depositor allow list:
		let depositorAddressesToAdd: [ThirdPartyDeposits.DepositorAddress] = localConfig
			.depositorsAllowList
			.filter { !inProfileConfig.depositorsAllowList.contains($0) }

		let depositorAddressesToRemove: [ThirdPartyDeposits.DepositorAddress] = inProfileConfig
			.depositorsAllowList
			.filter { !localConfig.depositorsAllowList.contains($0) }

		let accountAddress = state.account.address

		let manifest = try ManifestBuilder.make {
			if let depositorRuleChange {
				ManifestBuilder.setDefaultDepositorRule(accountAddress, depositorRuleChange)
			}

			for resourceAddress in assetExceptionsToBeRemoved {
				ManifestBuilder.removeResourcePreference(accountAddress, resourceAddress)
			}

			for assetException in assetExceptionsToAddOrUpdate {
				ManifestBuilder.setResourcePreference(accountAddress, assetException)
			}

			for depositorAddress in depositorAddressesToRemove {
				ManifestBuilder.removeAuthorizedDepositor(accountAddress, depositorAddress)
			}

			for depositorAddress in depositorAddressesToAdd {
				ManifestBuilder.addAuthorizedDepositor(accountAddress, depositorAddress)
			}
		}
		.build(networkId: state.account.networkID.rawValue)

		var updatedAccount = state.account
		updatedAccount.onLedgerSettings.thirdPartyDeposits = localConfig
		return (manifest, updatedAccount)
	}
}

extension ManifestBuilder {
	static let setDefaultDepositorRule = flip(setDefaultDepositorRule)
	static let setResourcePreference = flip(setResourcePreference)
	static let removeResourcePreference = flip(removeResourcePreference)
	static let addAuthorizedDepositor = flip(addAuthorizedDepositor)
	static let removeAuthorizedDepositor = flip(removeAuthorizedDepositor)

	func setDefaultDepositorRule(
		for account: AccountAddress,
		rule: ThirdPartyDeposits.DepositRule
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "set_default_deposit_rule",
			args: [rule.manifestValue]
		)
	}

	func setResourcePreference(
		for account: AccountAddress,
		assetException: ThirdPartyDeposits.AssetException
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "set_resource_preference",
			args: [.addressValue(value: assetException.address.intoManifestBuilderAddress()), assetException.exceptionRule.manifestValue]
		)
	}

	func removeResourcePreference(
		for account: AccountAddress,
		resource: ResourceAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "remove_resource_preference",
			args: [.addressValue(value: resource.intoManifestBuilderAddress())]
		)
	}

	func addAuthorizedDepositor(
		for account: AccountAddress,
		depositorAddress: ThirdPartyDeposits.DepositorAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "add_authorized_depositor",
			args: [depositorAddress.manifestValue()]
		)
	}

	func removeAuthorizedDepositor(
		for account: AccountAddress,
		depositorAddress: ThirdPartyDeposits.DepositorAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "remove_authorized_depositor",
			args: [depositorAddress.manifestValue()]
		)
	}
}

extension ThirdPartyDeposits.DepositorAddress {
	func manifestValue() throws -> ManifestBuilderValue {
		switch self {
		case let .resourceAddress(resourceAddress):
			try .enumValue(
				discriminator: 1,
				fields: [.addressValue(value: resourceAddress.intoManifestBuilderAddress())]
			)
		case let .nonFungibleGlobalID(nft):
			.enumValue(
				discriminator: 0,
				fields: [
					.tupleValue(fields: [
						.addressValue(value: .static(value: nft.resourceAddress())),
						.nonFungibleLocalIdValue(value: nft.localId()),
					]),
				]
			)
		}
	}
}

extension ThirdPartyDeposits.DepositAddressExceptionRule {
	var manifestValue: ManifestBuilderValue {
		let discriminator: UInt8 = switch self {
		case .allow:
			0
		case .deny:
			1
		}
		return .enumValue(discriminator: discriminator, fields: [])
	}
}

extension ThirdPartyDeposits.DepositRule {
	var manifestValue: ManifestBuilderValue {
		let discriminator: UInt8 = switch self {
		case .acceptAll:
			0
		case .denyAll:
			1
		case .acceptKnown:
			2
		}
		return .enumValue(discriminator: discriminator, fields: [])
	}
}
