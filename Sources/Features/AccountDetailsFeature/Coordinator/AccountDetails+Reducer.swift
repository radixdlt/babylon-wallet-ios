import AccountPortfoliosClient
import AccountPreferencesFeature
import AssetsFeature
import AssetTransferFeature
import BackupsClient
import EngineKit
import FeaturePrelude
import ImportMnemonicFeature
import NetworkSwitchingClient
import ProfileBackupsFeature
import SharedModels

// MARK: - ImportOrExportMnemonicForAccountPrompt
public struct ImportOrExportMnemonicForAccountPrompt: Sendable, Hashable {
	public let needed: Bool
	public let deepLinkTo: Bool
	public init(needed: Bool, deepLinkTo: Bool = false) {
		self.needed = needed
		self.deepLinkTo = deepLinkTo
	}

	public static let no = Self(needed: false, deepLinkTo: false)
}

// MARK: - ImportMnemonicForAccountPromptTag
public enum ImportMnemonicForAccountPromptTag {}

// MARK: - ExportMnemonicForAccountPromptTag
public enum ExportMnemonicForAccountPromptTag {}
public typealias ImportMnemonicPrompt = Tagged<ImportMnemonicForAccountPromptTag, ImportOrExportMnemonicForAccountPrompt>
public typealias ExportMnemonicPrompt = Tagged<ExportMnemonicForAccountPromptTag, ImportOrExportMnemonicForAccountPrompt>

extension Tagged where RawValue == ImportOrExportMnemonicForAccountPrompt {
	public static var no: Self { .init(rawValue: .no) }
	public init(needed: Bool, deepLinkTo: Bool = false) {
		self.init(rawValue: .init(needed: needed, deepLinkTo: deepLinkTo))
	}
}

// MARK: - AccountDetails
public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var account: Profile.Network.Account
		var assets: AssetsView.State

		public var importMnemonicPrompt: ImportMnemonicPrompt
		public var exportMnemonicPrompt: ExportMnemonicPrompt

		@PresentationState
		var destination: Destinations.State?

		fileprivate var deviceControlledFactorInstance: FactorInstance {
			switch account.securityState {
			case let .unsecured(control):
				return control.transactionSigning.factorInstance
			}
		}

		public init(
			for account: Profile.Network.Account,
			importMnemonicPrompt: ImportMnemonicPrompt = .no,
			exportMnemonicPrompt: ExportMnemonicPrompt = .no
		) {
			self.account = account
			self.assets = AssetsView.State(account: account, mode: .normal)
			self.importMnemonicPrompt = importMnemonicPrompt
			self.exportMnemonicPrompt = exportMnemonicPrompt
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
		case displayTransfer
		case refresh(AccountAddress)
	}

	public enum InternalAction: Sendable, Equatable {
		case transfer(hasMainnetEverBeenLive: Bool)

		case markBackupNeeded
		case accountUpdated(Profile.Network.Account)
		case portfolioLoaded(AccountPortfolio)

		case loadMnemonic
		case loadMnemonicResult(TaskResult<MnemonicWithPassphraseAndFactorSourceInfo>)

		case loadImport
		case loadProfileSnapshotForRecoverMnemonicsFlow(TaskResult<ProfileSnapshot>)
	}

	public struct MnemonicWithPassphraseAndFactorSourceInfo: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public let factorSourceKind: FactorSourceKind
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case preferences(AccountPreferences.State)
			case transfer(AssetTransfer.State)

			// FIXME: Rename `ImportMnemonic` -> `ExportOrImportMnemonic` ?
			case exportMnemonic(ImportMnemonic.State)

			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case preferences(AccountPreferences.Action)
			case transfer(AssetTransfer.Action)

			// FIXME: Rename `ImportMnemonic` -> `ExportOrImportMnemonic` ?
			case exportMnemonic(ImportMnemonic.Action)

			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.preferences, action: /Action.preferences) {
				AccountPreferences()
			}
			Scope(state: /State.transfer, action: /Action.transfer) {
				AssetTransfer()
			}
			Scope(state: /State.exportMnemonic, action: /Action.exportMnemonic) {
				// FIXME: Rename `ImportMnemonic` -> `ExportOrImportMnemonic` ?
				ImportMnemonic()
			}
			Scope(state: /State.importMnemonics, action: /Action.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.assets, action: /Action.child .. ChildAction.assets) {
			AssetsView()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { [state] send in
				func delay() async {
					// navigation bug if we try to "deep link" too fast..
					try? await clock.sleep(for: .milliseconds(900))
				}
				if state.importMnemonicPrompt.deepLinkTo {
					await delay()
					await send(.internal(.loadImport))
				} else if state.exportMnemonicPrompt.deepLinkTo {
					await delay()
					await send(.internal(.loadMnemonic))
				}
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
			return .run { send in
				let hasMainnetEverBeenLive = await networkSwitchingClient.hasMainnetEverBeenLive()
				await send(.internal(.transfer(hasMainnetEverBeenLive: hasMainnetEverBeenLive)))
			}

		case .exportMnemonicButtonTapped:
			return loadMnemonic(state: state)

		case .recoverMnemonicsButtonTapped:
			return loadImport()
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.transfer(.delegate(.dismissed)))):
			state.destination = nil
			return .none

		case .assets(.child(.fungibleTokenList(.delegate))):
			return .none

		case let .destination(.presented(.exportMnemonic(.delegate(.doneViewing(markedMnemonicAsBackedUp))))):
			if
				let justBackedUp = markedMnemonicAsBackedUp,
				state.exportMnemonicPrompt.needed,
				justBackedUp
			{
				state.exportMnemonicPrompt = .no
			}
			state.destination = nil
			return checkAccountSecurityPromptStatus(state: &state)

		case let .destination(.presented(.importMnemonics(.delegate(delegateAction)))):
			switch delegateAction {
			case .closeButtonTapped, .failedToImportAllRequiredMnemonics:
				break
			case let .finishedImportingMnemonics(_, imported):
				if imported.contains(where: { $0.factorSourceID == state.deviceControlledFactorInstance.factorSourceID }) {
					state.importMnemonicPrompt = .no

					// It makes no sense to prompt user to back up a mnemonic she *just* imported.
					state.exportMnemonicPrompt = .no
				}
			}
			state.destination = nil
			return checkAccountSecurityPromptStatus(state: &state)

		case .destination(.dismiss):
			loggerGlobal.feature("Dismissed child")
			return checkAccountSecurityPromptStatus(state: &state)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .transfer(hasMainnetEverBeenLive):
			state.destination = .transfer(.init(
				from: state.account,
				hasMainnetEverBeenLive: hasMainnetEverBeenLive
			))
			return .none

		case .markBackupNeeded:
			state.exportMnemonicPrompt = .init(needed: true)
			return .none

		case .loadMnemonic:
			return loadMnemonic(state: state)

		case .loadImport:
			return loadImport()

		case let .loadMnemonicResult(.success(mnemonicWithPassphraseAndFactorSourceInfo)):
			loggerGlobal.feature("Successfully loaded mnemonic to export")
			state.destination = .exportMnemonic(.init(
				warning: L10n.RevealSeedPhrase.warning,
				mnemonicWithPassphrase: mnemonicWithPassphraseAndFactorSourceInfo.mnemonicWithPassphrase,
				readonlyMode: .init(context: .fromBackupPrompt, factorSourceKind: mnemonicWithPassphraseAndFactorSourceInfo.factorSourceKind)
			))

			return .none

		case let .loadMnemonicResult(.failure(error)):
			loggerGlobal.error("Failed to load mnemonic to export")
			errorQueue.schedule(error)
			return .none

		case let .loadProfileSnapshotForRecoverMnemonicsFlow(.success(profileSnapshot)):
			state.destination = .importMnemonics(.init(profileSnapshot: profileSnapshot))
			return .none

		case let .loadProfileSnapshotForRecoverMnemonicsFlow(.failure(error)):
			loggerGlobal.error("Failed to load Profile to export")
			errorQueue.schedule(error)
			return .none

		case let .accountUpdated(account):
			state.account = account
			return reloadPortfolio(address: account.address)

		case let .portfolioLoaded(portfolio):
			state.assets.updatePortfolio(to: portfolio)
			return .none
		}
	}

	private func loadMnemonic(state: State) -> EffectTask<Action> {
		loggerGlobal.feature("implement export")
		let factorInstance = state.deviceControlledFactorInstance
		let factorSourceID = factorInstance.factorSourceID
		return .run { send in
			let result = await TaskResult {
				guard let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .displaySeedPhrase) else {
					loggerGlobal.error("Failed to find mnemonic with key: \(factorSourceID) which controls account: \(state.account)")
					struct UnabledToFindExpectedMnemonic: Swift.Error {}
					throw UnabledToFindExpectedMnemonic()
				}
				return MnemonicWithPassphraseAndFactorSourceInfo(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceKind: factorInstance.factorSourceKind
				)
			}
			await send(.internal(.loadMnemonicResult(result)))
		}
	}

	private func loadImport() -> EffectTask<Action> {
		.run { send in
			let result = await TaskResult { try await backupsClient.snapshotOfProfileForExport() }
			await send(.internal(.loadProfileSnapshotForRecoverMnemonicsFlow(result)))
		}
	}

	// FIXME: Refactor account security prompts to share logic between this reducer and Row+Reducer (AccountList)
	private func checkAccountSecurityPromptStatus(state: inout State) -> EffectTask<Action> {
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		if userDefaultsClient
			.getAddressesOfAccountsThatNeedRecovery()
			.contains(state.account.address)
		{
			// need to recover mnemonic since it has been previously skipped.
			state.importMnemonicPrompt = .init(needed: true)

			// do not care about export if import is needed
			return .none
		}

		let mightNeedToBeBackedUp: Bool = {
			switch state.account.securityState {
			case let .unsecured(unsecuredEntityControl):
				guard unsecuredEntityControl.transactionSigning.factorSourceID.kind == .device else {
					// Ledger account, mnemonics do not apply...
					return false
				}

				// check if already backed up
				let isAlreadyBackedUp = userDefaultsClient
					.getFactorSourceIDOfBackedUpMnemonics()
					.contains(unsecuredEntityControl.transactionSigning.factorSourceID)

				return !isAlreadyBackedUp
			}

		}()

		guard mightNeedToBeBackedUp else {
			return .none
		}

		return reloadPortfolio(address: state.account.address)
	}

	/// Reloads the portfolio and sets Backup Needed if necessary
	private func reloadPortfolio(address: AccountAddress) -> EffectTask<Action> {
		.run { send in
			guard let portfolio = try? await accountPortfoliosClient.fetchAccountPortfolio(address, false) else { return }

			let xrdResource = portfolio.fungibleResources.xrdResource

			if let xrdResource, xrdResource.amount > .zero {
				await send(.internal(.markBackupNeeded))
			}

			await send(.internal(.portfolioLoaded(portfolio.nonEmptyVaults)))
		}
	}
}
