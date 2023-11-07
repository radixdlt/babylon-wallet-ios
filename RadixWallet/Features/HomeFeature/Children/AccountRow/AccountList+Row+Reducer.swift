import ComposableArchitecture
import SwiftUI

// MARK: - DeviceFactorSourceControlled
public struct DeviceFactorSourceControlled: Sendable, Hashable {
	public let factorSourceID: FactorSourceID.FromHash
	public var importMnemonicNeeded = false {
		didSet {
			if importMnemonicNeeded {
				exportMnemonicNeeded = false
			}
		}
	}

	public var exportMnemonicNeeded = false
}

// MARK: - AccountWithInfo
public struct AccountWithInfo: Sendable, Hashable {
	public var account: Profile.Network.Account {
		didSet {
			self.deviceFactorSourceControlled = Self.makeDeviceFactorSourceControlled(account)
		}
	}

	public var isDappDefinitionAccount: Bool = false
	public var deviceFactorSourceControlled: DeviceFactorSourceControlled?

	init(account: Profile.Network.Account) {
		self.account = account
		self.deviceFactorSourceControlled = Self.makeDeviceFactorSourceControlled(account)
	}

	private static func makeDeviceFactorSourceControlled(_ account: Profile.Network.Account) -> DeviceFactorSourceControlled? {
		switch account.securityState {
		case let .unsecured(unsecuredEntityControl):
			if unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device {
				DeviceFactorSourceControlled(
					factorSourceID: unsecuredEntityControl.transactionSigning.factorSourceID
				)
			} else {
				nil
			}
		}
	}

	public var id: AccountAddress { account.address }
	public var isLegacyAccount: Bool { account.isOlympiaAccount }
	public var isLedgerAccount: Bool { account.isLedgerAccount }

	public var importMnemonicNeeded: Bool {
		deviceFactorSourceControlled?.importMnemonicNeeded ?? false
	}

	public var exportMnemonicNeeded: Bool {
		deviceFactorSourceControlled?.exportMnemonicNeeded ?? false
	}
}

// MARK: - AccountWithInfoHolder
public protocol AccountWithInfoHolder {
	var accountWithInfo: AccountWithInfo { get set }
}

extension AccountWithInfoHolder {
	public var account: Profile.Network.Account {
		get { accountWithInfo.account }
		set { accountWithInfo.account = newValue }
	}

	public var isLegacyAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isLedgerAccount: Bool { accountWithInfo.isLedgerAccount }
	public var isDappDefinitionAccount: Bool {
		get { accountWithInfo.isDappDefinitionAccount }
		set { accountWithInfo.isDappDefinitionAccount = newValue }
	}

	public var deviceFactorSourceControlled: DeviceFactorSourceControlled? {
		get { accountWithInfo.deviceFactorSourceControlled }
		set { accountWithInfo.deviceFactorSourceControlled = newValue }
	}

	public var importMnemonicNeeded: Bool {
		accountWithInfo.importMnemonicNeeded
	}

	public var exportMnemonicNeeded: Bool {
		accountWithInfo.exportMnemonicNeeded
	}
}

extension AccountWithInfoHolder {
	/*
	 	func accountSecurityCheck(
	 	account: Profile.Network.Account,
	 	portfolio: OnLedgerEntity.Account?
	 ) -> DeviceFactorSourceControlled? {
	 	if let portfolio, account.address != portfolio.address {
	 		assertionFailure("Discrepancy, wrong owner")
	 	}

	 	return accountSecurityCheck(account: account, xrdResource: portfolio?.fungibleResources.xrdResource)
	 }

	 func accountSecurityCheck(
	 	account: Profile.Network.Account,
	 	xrdResource: OnLedgerEntity.OwnedFungibleResource?
	 ) -> DeviceFactorSourceControlled? {
	 */
	mutating func updateMnemonicPromptsIfNeeded(portfolio: OnLedgerEntity.Account? = nil) {
		if let portfolio, account.address != portfolio.address {
			assertionFailure("Discrepancy, wrong owner")
		}
		updateMnemonicPromptsIfNeeded(xrdResource: portfolio?.fungibleResources.xrdResource)
	}

	mutating func updateMnemonicPromptsIfNeeded(xrdResource: OnLedgerEntity.OwnedFungibleResource? = nil) {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		guard let factorSourceID = { () -> FactorSourceID.FromHash? in
			switch account.securityState {
			case let .unsecured(uc) where uc.transactionSigning.factorSourceID.kind == .device:
				return uc.transactionSigning.factorSourceID
			default: return nil
			}
		}() else {
			return
		}

		let importMnemonicNeeded = !secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSourceID)
		if importMnemonicNeeded {
			if deviceFactorSourceControlled == nil {
				self.deviceFactorSourceControlled = .init(factorSourceID: factorSourceID, importMnemonicNeeded: true)
			} else {
				self.deviceFactorSourceControlled?.importMnemonicNeeded = true
			}
		}

		guard let xrdResource else {
			return
		}

		let hasValue = xrdResource.amount > 0

		let hasAlreadyBackedUpMnemonic = userDefaultsClient.getFactorSourceIDOfBackedUpMnemonics().contains(factorSourceID)

		let exportMnemonicNeeded = !hasAlreadyBackedUpMnemonic && hasValue

		if deviceFactorSourceControlled == nil {
			self.deviceFactorSourceControlled = .init(factorSourceID: factorSourceID, exportMnemonicNeeded: exportMnemonicNeeded)
		} else {
			self.deviceFactorSourceControlled?.exportMnemonicNeeded = exportMnemonicNeeded
		}
	}
}

// MARK: - Home.AccountRow
extension Home {
	public struct AccountRow: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable, AccountWithInfoHolder {
			public var id: AccountAddress { account.address }
			public var accountWithInfo: AccountWithInfo

			public var portfolio: Loadable<OnLedgerEntity.Account>

			public init(
				account: Profile.Network.Account
			) {
				self.accountWithInfo = .init(account: account)
				self.portfolio = .loading
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case tapped
			case task
			case backUpMnemonic
			case importMnemonic
		}

		public enum InternalAction: Sendable, Equatable {
			case accountPortfolioUpdate(OnLedgerEntity.Account)
			case accountSecurityCheck
		}

		public enum DelegateAction: Sendable, Equatable {
			case openDetails
			case exportMnemonic
			case importMnemonics
		}

		@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				let accountAddress = state.account.address
				if state.portfolio.wrappedValue == nil {
					state.portfolio = .loading
				}

				checkIfCallActionIsNeeded(state: &state)

				return .run { send in
					for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress) {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.accountPortfolioUpdate(accountPortfolio.nonEmptyVaults)))
					}
				}
			case .backUpMnemonic:
				return .send(.delegate(.exportMnemonic))

			case .importMnemonic:
				return .send(.delegate(.importMnemonics))

			case .tapped:
				return .send(.delegate(.openDetails))
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .accountPortfolioUpdate(portfolio):
				state.isDappDefinitionAccount = portfolio.metadata.accountType == .dappDefinition
				assert(portfolio.address == state.account.address)
				state.portfolio = .success(portfolio)
				return .send(.internal(.accountSecurityCheck))
			case .accountSecurityCheck:
				checkIfCallActionIsNeeded(state: &state)
				return .none
			}
		}

		private func checkIfCallActionIsNeeded(state: inout State) {
			state.updateMnemonicPromptsIfNeeded(portfolio: state.portfolio.wrappedValue)
		}
	}
}
