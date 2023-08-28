import AccountsClient
import DappInteractionClient
import EngineKit
import FeaturePrelude
import OverlayWindowClient

public typealias ThirdPartyDeposits = Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits

// MARK: - ManageThirdPartyDeposits
public struct ManageThirdPartyDeposits: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account

		var depositRule: ThirdPartyDeposits.DepositRule {
			account.onLedgerSettings.thirdPartyDeposits.depositRule
		}

		@PresentationState
		var destinations: Destinations.State? = nil

		init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case updateTapped
		case rowTapped(ManageThirdPartyDeposits.Section.Row)
	}

	public enum DelegateAction: Equatable, Sendable {
		case accountUpdated
	}

	public enum ChildAction: Equatable, Sendable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: ReducerProtocol, Sendable {
		public enum State: Equatable, Hashable, Sendable {
			case allowDenyAssets(ResourcesList.State)
			case allowDepositors(ResourcesList.State)
		}

		public enum Action: Equatable, Sendable {
			case allowDenyAssets(ResourcesList.Action)
			case allowDepositors(ResourcesList.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.allowDenyAssets, action: /Action.allowDenyAssets) {
				ResourcesList()
			}

			Scope(state: /State.allowDepositors, action: /Action.allowDepositors) {
				ResourcesList()
			}
		}
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .rowTapped(row):
			switch row {
			case let .depositRule(rule):
				state.account.onLedgerSettings.thirdPartyDeposits.depositRule = rule

			case .allowDenyAssets:
				state.destinations = .allowDenyAssets(.init(
					mode: .allowDenyAssets(.allow),
					thirdPartyDeposits: state.account.onLedgerSettings.thirdPartyDeposits
				))

			case .allowDepositors:
				state.destinations = .allowDepositors(.init(
					mode: .allowDepositors,
					thirdPartyDeposits: state.account.onLedgerSettings.thirdPartyDeposits
				))
			}
			return .none

		case .updateTapped:
			@Dependency(\.accountsClient) var accountsClient
			@Dependency(\.errorQueue) var errorQueue

			// Are there any updates

			let onLedgerConfig = state.account.onLedgerSettings.thirdPartyDeposits
			let localConfig = state.thirdPartyDeposits

			// 1. Deposit rule change
			let depositorRule = onLedgerConfig.depositRule != localConfig.depositRule ? localConfig.depositRule : nil

			// 2. assetException changes:
			let assetExceptionsToAddOrUpdate = localConfig.assetsExceptionList.filter { localException in
				guard let onLedgerException = onLedgerConfig.assetsExceptionList.first(where: { $0.address == localException.address }) else {
					// New exception to be added on Ledger
					return true
				}
				// Exception rule did change
				return onLedgerException.exceptionRule != localException.exceptionRule
			}
			let assetExceptionsToBeRemoved = onLedgerConfig
				.assetsExceptionList
				.filter {
					!localConfig.assetsExceptionList.contains($0)
				}.map(\.address)

			// 3. Depositor allow list:
			let depositorAddressesToAdd = localConfig.depositorsAllowList.filter { !onLedgerConfig.depositorsAllowList.contains($0) }
			let depositorAddressesToRemove = onLedgerConfig.depositorsAllowList.filter { !localConfig.depositorsAllowList.contains($0) }

			let accountAddress = state.account.address

			let manifest = try! ManifestBuilder.make {
				if let depositorRule {
					ManifestBuilder.setDefaultDepositorRule(accountAddress, depositorRule)
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
			}.build(networkId: state.account.networkID.rawValue)

			return .run { [account = state.account] _ in
				do {
					try await dappInteractionClient.addWalletInteraction(.transaction(.init(send: .init(version: .default, transactionManifest: manifest, message: "Update third party deposits"))))
					// try await accountsClient.updateAccount(account)
					// TODO: schedule TX
					// await send(.delegate(.accountUpdated))
				} catch {
					errorQueue.schedule(error)
				}
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.allowDenyAssets(.delegate(.updated(thirdPartyDeposits))))),
		     let .destinations(.presented(.allowDepositors(.delegate(.updated(thirdPartyDeposits))))):
			state.account.onLedgerSettings.thirdPartyDeposits = thirdPartyDeposits
			return .none
		case .destinations:
			return .none
		}
	}
}

extension ManifestBuilder {
	static let setDefaultDepositorRule = flip(setDefaultDepositorRule)
	static let setResourcePreference = flip(setResourcePreference)
	static let removeResourcePreference = flip(removeResourcePreference)
	static let addAuthorizedDepositor = flip(addAuthorizedDepositor)
	static let removeAuthorizedDepositor = flip(removeAuthorizedDepositor)

	public func setDefaultDepositorRule(
		for account: AccountAddress,
		rule: ThirdPartyDeposits.DepositRule
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "set_default_deposit_rule",
			args: [rule.manifestValue]
		)
	}

	public func setResourcePreference(
		for account: AccountAddress,
		assetException: ThirdPartyDeposits.AssetException
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "set_resource_preference",
			args: [.addressValue(value: assetException.address.intoManifestBuilderAddress()), assetException.exceptionRule.manifestValue]
		)
	}

	public func removeResourcePreference(
		for account: AccountAddress,
		resource: ResourceAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "remove_resource_preference",
			args: [.addressValue(value: resource.intoManifestBuilderAddress())]
		)
	}

	public func addAuthorizedDepositor(
		for account: AccountAddress,
		depositorAddress: ThirdPartyDeposits.DepositorAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "add_authorized_depositor",
			args: [depositorAddress.manifestValue]
		)
	}

	public func removeAuthorizedDepositor(
		for account: AccountAddress,
		depositorAddress: ThirdPartyDeposits.DepositorAddress
	) throws -> ManifestBuilder {
		try callMethod(
			address: account.intoManifestBuilderAddress(),
			methodName: "remove_authorized_depositor",
			args: [depositorAddress.manifestValue]
		)
	}
}

extension ThirdPartyDeposits.DepositorAddress {
	var manifestValue: ManifestBuilderValue {
		switch self {
		case let .resourceAddress(resourceAddress):
			return try! .enumValue(discriminator: 0, fields: [.addressValue(value: resourceAddress.intoManifestBuilderAddress())])
		case let .nonFungibleGlobalID(nft):
			return .enumValue(discriminator: 1, fields: [.nonFungibleLocalIdValue(value: nft.localId())])
		}
	}
}

extension ThirdPartyDeposits.DepositAddressExceptionRule {
	var manifestValue: ManifestBuilderValue {
		let discriminator: UInt8 = {
			switch self {
			case .allow:
				return 0
			case .deny:
				return 1
			}
		}()
		return .enumValue(discriminator: discriminator, fields: [])
	}
}

extension ThirdPartyDeposits.DepositRule {
	var manifestValue: ManifestBuilderValue {
		let discriminator: UInt8 = {
			switch self {
			case .acceptAll:
				return 0
			case .denyAll:
				return 1
			case .acceptKnown:
				return 2
			}
		}()
		return .enumValue(discriminator: discriminator, fields: [])
	}
}
