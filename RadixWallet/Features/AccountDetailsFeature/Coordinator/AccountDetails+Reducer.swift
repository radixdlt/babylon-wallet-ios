import ComposableArchitecture
import SwiftUI

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

		fileprivate var deviceControlledFactorInstance: HierarchicalDeterministicFactorInstance {
			switch account.securityState {
			case let .unsecured(control):
				control.transactionSigning
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
		case markBackupNeeded
		case accountUpdated(Profile.Network.Account)

		case loadMnemonic
		case loadMnemonicResult(TaskResult<MnemonicWithPassphraseAndFactorSourceInfo>)

		case loadImport
		case loadProfileSnapshotForRecoverMnemonicsFlow(TaskResult<ProfileSnapshot>)
	}

	public struct MnemonicWithPassphraseAndFactorSourceInfo: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public let factorSourceKind: FactorSourceKind
	}

	public struct Destinations: Sendable, Reducer {
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

		public var body: some Reducer<State, Action> {
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
			state.destination = .transfer(.init(
				from: state.account
			))
			return .none

		case .exportMnemonicButtonTapped:
			return loadMnemonic(state: state)

		case .recoverMnemonicsButtonTapped:
			return loadImport()
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
				if imported.contains(where: { $0.factorSourceID == state.deviceControlledFactorInstance.factorSourceID.embed() }) {
					state.importMnemonicPrompt = .no

					// It makes no sense to prompt user to back up a mnemonic she *just* imported.
					state.exportMnemonicPrompt = .no
				}
			}
			state.destination = nil
			return checkAccountSecurityPromptStatus(state: &state)

		case .destination(.dismiss):
			return checkAccountSecurityPromptStatus(state: &state)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .markBackupNeeded:
			state.exportMnemonicPrompt = .init(needed: true)
			return .none

		case .loadMnemonic:
			return loadMnemonic(state: state)

		case .loadImport:
			return loadImport()

		case let .loadMnemonicResult(.success(mnemonicWithPassphraseAndFactorSourceInfo)):
			loggerGlobal.trace("Successfully loaded mnemonic to export")
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
			return .none
		}
	}

	private func loadMnemonic(state: State) -> Effect<Action> {
		let factorInstance = state.deviceControlledFactorInstance
		let factorSourceID = factorInstance.factorSourceID
		return .run { send in
			let result = await TaskResult {
				guard let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorInstance.factorSourceID, .displaySeedPhrase) else {
					loggerGlobal.error("Failed to find mnemonic with key: \(factorSourceID) which controls account: \(state.account)")
					struct UnabledToFindExpectedMnemonic: Swift.Error {}
					throw UnabledToFindExpectedMnemonic()
				}
				return MnemonicWithPassphraseAndFactorSourceInfo(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceKind: factorInstance.factorInstance.factorSourceKind
				)
			}
			await send(.internal(.loadMnemonicResult(result)))
		}
	}

	private func loadImport() -> Effect<Action> {
		.run { send in
			let result = await TaskResult { try await backupsClient.snapshotOfProfileForExport() }
			await send(.internal(.loadProfileSnapshotForRecoverMnemonicsFlow(result)))
		}
	}

	// FIXME: Refactor account security prompts to share logic between this reducer and Row+Reducer (AccountList)
	private func checkAccountSecurityPromptStatus(state: inout State) -> Effect<Action> {
		@Dependency(\.userDefaultsClient) var userDefaultsClient

		if userDefaultsClient
			.getAddressesOfAccountsThatNeedRecovery()
			.contains(state.account.address)
		{
			// need to recover mnemonic since it has been previously skipped.
			state.importMnemonicPrompt = .init(needed: true)

			// do not care about export if import SwiftUI
			import ComposableArchitecture return .none
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

		return .run { [address = state.account.address] send in
			guard let portfolio = try? await accountPortfoliosClient.fetchAccountPortfolio(address, false) else { return }

			let xrdResource = portfolio.fungibleResources.xrdResource

			if let xrdResource, xrdResource.amount > .zero {
				await send(.internal(.markBackupNeeded))
			}
		}
	}
}
