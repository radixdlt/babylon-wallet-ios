import ComposableArchitecture
import SwiftUI

// MARK: - AccountPreferences
struct AccountPreferences: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum SecurityState: Hashable {
			case unsecurified(FactorSourcesList.Row)
			case securified
		}

		var account: Account
		var securityState: SecurityState?
		var faucetButtonState: ControlState
		var address: AccountAddress { account.address }
		var isOnMainnet: Bool { account.networkID == .mainnet }

		@PresentationState
		var destination: Destination.State? = nil

		init(
			account: Account,
			faucetButtonState: ControlState = .enabled
		) {
			self.account = account
			self.faucetButtonState = faucetButtonState
		}
	}

	// MARK: - Action

	enum ViewAction: Sendable, Equatable {
		case task
		case rowTapped(AccountPreferences.Section.SectionRow)
		case hideAccountTapped
		case deleteAccountTapped
		case faucetButtonTapped
		case factorSourceCardTapped(FactorSourcesList.Row)
		case factorSourceMessageTapped(FactorSourcesList.Row)
		case applyShieldButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case accountUpdated(Account)
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState = .enabled)
		case refreshAccountCompleted(TaskResult<OnLedgerEntity.OnLedgerAccount>)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		case securityStateDetermined(State.SecurityState)
	}

	enum DelegateAction: Sendable, Equatable {
		case accountHidden
		case goHomeAfterAccountDeleted
	}

	// MARK: - Destination
	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case updateAccountLabel(RenameLabel.State)
			case thirdPartyDeposits(ManageThirdPartyDeposits.State)
			case devPreferences(DevAccountPreferences.State)
			case hideAccount
			case deleteAccount(DeleteAccountCoordinator.State)
			case factorSourceDetail(FactorSourceDetail.State)
			case displayMnemonic(DisplayMnemonic.State)
			case enterMnemonic(ImportMnemonicForFactorSource.State)
			case selectShield(SelectShield.State)
			case applyShield(ApplyShield.Coordinator.State)
			case shieldDetails(EntityShieldDetails.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case updateAccountLabel(RenameLabel.Action)
			case thirdPartyDeposits(ManageThirdPartyDeposits.Action)
			case devPreferences(DevAccountPreferences.Action)
			case hideAccount(ConfirmationAction)
			case deleteAccount(DeleteAccountCoordinator.Action)
			case factorSourceDetail(FactorSourceDetail.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case enterMnemonic(ImportMnemonicForFactorSource.Action)
			case selectShield(SelectShield.Action)
			case applyShield(ApplyShield.Coordinator.Action)
			case shieldDetails(EntityShieldDetails.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.updateAccountLabel, action: \.updateAccountLabel) {
				RenameLabel()
			}
			Scope(state: \.thirdPartyDeposits, action: \.thirdPartyDeposits) {
				ManageThirdPartyDeposits()
			}
			Scope(state: \.devPreferences, action: \.devPreferences) {
				DevAccountPreferences()
			}
			Scope(state: \.deleteAccount, action: \.deleteAccount) {
				DeleteAccountCoordinator()
			}
			Scope(state: \.factorSourceDetail, action: \.factorSourceDetail) {
				FactorSourceDetail()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.enterMnemonic, action: \.enterMnemonic) {
				ImportMnemonicForFactorSource()
			}
			Scope(state: \.selectShield, action: \.selectShield) {
				SelectShield()
			}
			Scope(state: \.applyShield, action: \.applyShield) {
				ApplyShield.Coordinator()
			}
			Scope(state: \.shieldDetails, action: \.shieldDetails) {
				EntityShieldDetails()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [address = state.account.address] send in
				for try await accountUpdate in await accountsClient.accountUpdates(address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}
			.merge(with: state.isOnMainnet ? .none : loadIsAllowedToUseFaucet(&state))

		case let .rowTapped(row):
			return destination(for: row, &state)

		case .hideAccountTapped:
			state.destination = .hideAccount
			return .none

		case .deleteAccountTapped:
			state.destination = .deleteAccount(.init(account: state.account))
			return .none

		case .faucetButtonTapped:
			return call(buttonState: \.faucetButtonState, into: &state) {
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: $0))
			}

		case let .factorSourceCardTapped(row):
			state.destination = .factorSourceDetail(.init(integrity: row.integrity))
			return .none

		case let .factorSourceMessageTapped(row):
			switch row.status {
			case .seedPhraseWrittenDown, .notBackedUp:
				return .none

			case .seedPhraseNotRecoverable:
				return exportMnemonic(integrity: row.integrity) {
					state.destination = .displayMnemonic(.init(mnemonic: $0.mnemonicWithPassphrase.mnemonic, factorSourceID: $0.factorSourceID))
				}

			case .lostFactorSource:
				state.destination = .enterMnemonic(.init(
					deviceFactorSource: row.integrity.factorSource.asDevice!,
					profileToCheck: .current
				))
				return .none

			case .none:
				return .none
			}

		case .applyShieldButtonTapped:
			state.destination = .selectShield(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(updated):
			state.account = updated
			return loadSecState(state: state)

		case let .isAllowedToUseFaucet(.success(value)):
			state.faucetButtonState = value ? .enabled : .disabled
			return .none

		case let .isAllowedToUseFaucet(.failure(error)):
			state.faucetButtonState = .disabled
			errorQueue.schedule(error)
			return .none

		case let .hideLoader(controlStateKeyPath):
			state[keyPath: controlStateKeyPath] = .enabled
			return .none

		case .refreshAccountCompleted:
			state.faucetButtonState = .disabled
			return .none

		case let .callDone(controlStateKeyPath, changeTo):
			if controlStateKeyPath == \State.faucetButtonState {
				// NB: This call to update might be superfluous, since after any transaction we fetch all accounts
				return updateAccountPortfolio(state).concatenate(with: loadIsAllowedToUseFaucet(&state))
			} else {
				state[keyPath: controlStateKeyPath] = changeTo
				return .none
			}

		case let .securityStateDetermined(securityState):
			state.securityState = securityState
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .updateAccountLabel(.delegate(.labelUpdated)),
		     .thirdPartyDeposits(.delegate(.accountUpdated)):
			state.destination = nil
			return .none
		case .hideAccount(.confirm):
			state.destination = nil
			return hideAccountEffect(state: state)
		case .deleteAccount(.delegate(.goHomeAfterAccountDeleted)):
			return .send(.delegate(.goHomeAfterAccountDeleted))
		case .hideAccount(.cancel):
			state.destination = nil
			return .none
		case .enterMnemonic(.delegate(.closed)):
			state.destination = nil
			return .none
		case .enterMnemonic(.delegate(.imported)):
			state.destination = nil
			return loadSecState(state: state)
		case .displayMnemonic(.delegate(.backedUp)):
			state.destination = nil
			return loadSecState(state: state)
		case let .selectShield(.delegate(.confirmed(shield))):
			state.destination = .applyShield(.init(securityStructure: shield, selectedAccounts: [state.account.address], root: .completion))
			return .none
		case .applyShield(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	private func hideAccountEffect(state: State) -> Effect<Action> {
		.run { [account = state.account] send in
			try await entitiesVisibilityClient.hideAccount(account.id)
			overlayWindowClient.scheduleHUD(.accountHidden)
			await send(.delegate(.accountHidden))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func loadSecState(state: State) -> Effect<Action> {
		switch state.account.securityState {
		case let .unsecured(control):
			.run { send in
				if let fs = try? await factorSourcesClient.getFactorSource(of: control.transactionSigning.factorInstance) {
					let integrity = try await SargonOS.shared.factorSourceIntegrity(factorSource: fs)
					let factorSourceRowState = FactorSourcesList.Row(
						integrity: integrity,
						linkedEntities: .init(accounts: [], personas: [], hasHiddenEntities: false),
						status: .init(integrity: integrity),
						selectability: .selectable
					)
					await send(.internal(.securityStateDetermined(.unsecurified(factorSourceRowState))))
				}
			}
		case .securified:
			.send(.internal(.securityStateDetermined(.securified)))
		}
	}
}

extension AccountPreferences {
	private func call(
		buttonState: WritableKeyPath<State, ControlState>,
		into state: inout State,
		onSuccess: ControlState = .enabled,
		call: @escaping @Sendable (AccountAddress) async throws -> Void
	) -> Effect<Action> {
		state[keyPath: buttonState] = .loading(.local)
		return .run { [address = state.address] send in
			try await call(address)
			await send(.internal(.callDone(updateControlState: buttonState, changeTo: onSuccess)))
		} catch: { error, send in
			await send(.internal(.hideLoader(updateControlState: buttonState)))
			if !Task.isCancelled {
				errorQueue.schedule(error)
			}
		}
	}

	private func updateAccountPortfolio(_ state: State) -> Effect<Action> {
		.run { [address = state.address] send in
			await send(.internal(.refreshAccountCompleted(
				TaskResult { try await accountPortfoliosClient.fetchAccountPortfolio(address, true).account }
			)))
		}
	}

	private func loadIsAllowedToUseFaucet(_ state: inout State) -> Effect<Action> {
		state.faucetButtonState = .loading(.local)
		return .run { [address = state.address] send in
			await send(.internal(.isAllowedToUseFaucet(
				TaskResult {
					await faucetClient.isAllowedToUseFaucet(address)
				}
			)))
		}
	}
}

extension OverlayWindowClient.Item.HUD {
	static let accountHidden = Self(text: L10n.AccountSettings.accountHidden)
}

extension AccountPreferences {
	func destination(for row: AccountPreferences.Section.SectionRow, _ state: inout State) -> Effect<Action> {
		switch row {
		case .personalize(.accountLabel):
			state.destination = .updateAccountLabel(.init(kind: .account(state.account)))
			return .none

		case .personalize(.accountColor):
			return .none

		case .personalize(.tags):
			return .none

		case .onLedger(.thirdPartyDeposits):
			state.destination = .thirdPartyDeposits(.init(account: state.account))
			return .none

		case .onLedger(.accountSecurity):
			return .none

		case .dev(.devPreferences):
			state.destination = .devPreferences(.init(account: state.account))
			return .none

		case .securifiedWith(.shield):
			state.destination = .shieldDetails(.init(entityAddress: .account(state.account.address)))
			return .none
		}
	}
}
