import AccountsClient
import AddLedgerFactorSourceFeature
import ChooseLedgerHardwareDeviceFeature
import Cryptography
import DerivePublicKeyFeature
import FeaturePrelude
import LedgerHardwareWalletClient

public struct CreationOfAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let name: NonEmptyString
		public let networkID: NetworkID?
		public let isCreatingLedgerAccount: Bool
		public enum Step: Sendable, Hashable {
			case step0_chooseLedger(ChooseLedgerHardwareDevice.State)
			case step1_derivePublicKey(DerivePublicKey.State)
		}

		public var step: Step

		public init(
			name: NonEmptyString,
			networkID: NetworkID?,
			isCreatingLedgerAccount: Bool
		) {
			self.name = name
			self.networkID = networkID
			self.isCreatingLedgerAccount = isCreatingLedgerAccount

			self.step = isCreatingLedgerAccount ? .step0_chooseLedger(.init()) : .step1_derivePublicKey(
				.init(
					derivationPathOption: .next(networkID: networkID),
					factorSourceOption: .device
				)
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case createAccountResult(TaskResult<Profile.Network.Account>)
	}

	public enum ChildAction: Sendable, Equatable {
		case step0_chooseLedger(ChooseLedgerHardwareDevice.Action)
		case step1_derivePublicKey(DerivePublicKey.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdAccount(Profile.Network.Account)
		case createAccountFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.step0_chooseLedger,
				action: /Action.child .. ChildAction.step0_chooseLedger
			) {
				ChooseLedgerHardwareDevice()
			}
			Scope(
				state: /State.Step.step1_derivePublicKey,
				action: /Action.child .. ChildAction.step1_derivePublicKey
			) {
				DerivePublicKey()
			}
		}

		Reduce(core)
	}

//	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
//		switch viewAction {
//		case .appeared:
//			switch state.genesisFactorSourceSelection {
//			case let .device(babylonDeviceFactorSource):
//				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
//			case let .ledger(ledgers):
//				precondition(ledgers.allSatisfy { $0.kind == .ledgerHQHardwareWallet })
//				state.ledgers = IdentifiedArrayOf<FactorSource>.init(uniqueElements: ledgers, id: \.id)
//				if let first = ledgers.first {
//					state.selectedLedgerID = first.id
//				}
//				return .none
//			}
//		}
//	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createAccountResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createAccountFailed))

		case let .createAccountResult(.success(account)):
			return .send(.delegate(.createdAccount(account)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .step0_chooseLedger(.delegate(.choseLedger(ledger))):
			state.step = .step1_derivePublicKey(.init(
				derivationPathOption: .next(networkID: state.networkID),
				factorSourceOption: .specific(ledger.factorSource)
			))
			return .none

		case let .step1_derivePublicKey(.delegate(.derivedPublicKey(publicKey, derivationPath, factorSourceID, networkID))):
			return .run { [name = state.name] send in
				await send(.internal(.createAccountResult(TaskResult {
					try await accountsClient.newVirtualAccount(.init(
						name: name,
						factorInstance: .init(
							factorSourceID: factorSourceID,
							publicKey: publicKey,
							derivationPath: derivationPath
						),
						networkID: networkID
					))
				})))
			}

		default: return .none
		}
	}
}
