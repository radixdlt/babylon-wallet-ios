import AccountPortfoliosClient
import AccountPreferencesFeature
import AssetsFeature
import AssetTransferFeature
import BackupsClient
import EngineKit
import FeaturePrelude
import ImportMnemonicFeature
import ProfileBackupsFeature
import SharedModels

public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var account: Profile.Network.Account
		var assets: AssetsView.State

		public enum CallToAction: Sendable, Hashable {
			case needToBackupMnemonicForThisAccount
			case needToImportMnemonicForThisAccount
		}

		public var callToAction: CallToAction?

		@PresentationState
		var destination: Destinations.State?

		public init(
			for account: Profile.Network.Account,
			callToAction: CallToAction? = nil
		) {
			self.account = account
			self.assets = AssetsView.State(account: account, mode: .normal)
			self.callToAction = callToAction
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
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient

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
			return .run { [address = state.account.address] send in
				for try await accountUpdate in await accountsClient.accountUpdates(address) {
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
			state.destination = .transfer(AssetTransfer.State(from: state.account))
			return .none

		case .exportMnemonicButtonTapped:
			return loadMnemonic(account: state.account)

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

		case .destination(.presented(.exportMnemonic(.delegate(.doneViewing)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.importMnemonics(.delegate(delegateAction)))):
			switch delegateAction {
			case .closeButtonTapped, .failedToImportAllRequiredMnemonics, .finishedImportingMnemonics:
				break
			}
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .loadMnemonic:
			return loadMnemonic(account: state.account)

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
			return .none
		}
	}

	private func loadMnemonic(account: Profile.Network.Account) -> EffectTask<Action> {
		loggerGlobal.feature("implement export")
		let factorInstance: FactorInstance = {
			switch account.securityState {
			case let .unsecured(control): return control.transactionSigning.factorInstance
			}
		}()
		let factorSourceID = factorInstance.factorSourceID
		return .task {
			let result = await TaskResult {
				guard let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .displaySeedPhrase) else {
					loggerGlobal.error("Failed to find mnemonic with key: \(factorSourceID) which controls account: \(account)")
					struct UnabledToFindExpectedMnemonic: Swift.Error {}
					throw UnabledToFindExpectedMnemonic()
				}
				return MnemonicWithPassphraseAndFactorSourceInfo(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceKind: factorInstance.factorSourceKind
				)
			}
			return .internal(.loadMnemonicResult(result))
		}
	}

	private func loadImport() -> EffectTask<Action> {
		loggerGlobal.feature("implement import")
		return .task {
			let result = await TaskResult { try await backupsClient.snapshotOfProfileForExport() }
			return .internal(.loadProfileSnapshotForRecoverMnemonicsFlow(result))
		}
	}
}
