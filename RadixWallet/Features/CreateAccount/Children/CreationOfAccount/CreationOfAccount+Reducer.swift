import ComposableArchitecture
import SwiftUI
public struct CreationOfAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let name: NonEmptyString
		public let networkID: NetworkID?
		public let isCreatingLedgerAccount: Bool
		public enum Step: Sendable, Hashable {
			case step0_chooseLedger(LedgerHardwareDevices.State)
			case step1_derivePublicKeys(DerivePublicKeys.State)
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

			if isCreatingLedgerAccount {
				self.step = .step0_chooseLedger(.init(context: .createHardwareAccount))
			} else {
				self.step = .step1_derivePublicKeys(
					.init(
						derivationPathOption: .next(
							for: .account,
							networkID: networkID,
							curve: .curve25519,
							scheme: .cap26
						),
						factorSourceOption: .device,
						purpose: .createNewEntity(kind: .account)
					)
				)
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case createAccountResult(TaskResult<Profile.Network.Account>)
	}

	public enum ChildAction: Sendable, Equatable {
		case step0_chooseLedger(LedgerHardwareDevices.Action)
		case step1_derivePublicKeys(DerivePublicKeys.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdAccount(Profile.Network.Account)
		case createAccountFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.step0_chooseLedger,
				action: /Action.child .. ChildAction.step0_chooseLedger
			) {
				LedgerHardwareDevices()
			}
			Scope(
				state: /State.Step.step1_derivePublicKeys,
				action: /Action.child .. ChildAction.step1_derivePublicKeys
			) {
				DerivePublicKeys()
			}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .createAccountResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createAccountFailed))

		case let .createAccountResult(.success(account)):
			return .run { send in
				try await accountsClient.saveVirtualAccount(account)
				await send(.delegate(.createdAccount(account)))
			} catch: { error, send in
				loggerGlobal.error("Failed to save newly created virtual account into profile: \(error)")
				await send(.delegate(.createAccountFailed))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .step0_chooseLedger(.delegate(.choseLedger(ledger))):
			state.step = .step1_derivePublicKeys(
				.init(
					derivationPathOption: .next(
						for: .account,
						networkID: state.networkID,
						curve: .curve25519,
						scheme: .cap26
					),
					factorSourceOption: .specific(ledger.embed()),
					purpose: .createNewEntity(kind: .account)
				)
			)
			return .none

		case let .step1_derivePublicKeys(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, networkID))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create account expected one single key, got: \(hdKeys.count)")
				return .send(.delegate(.createAccountFailed))
			}

			return .run { [name = state.name] send in
				await send(.internal(.createAccountResult(TaskResult {
					try await accountsClient.newVirtualAccount(.init(
						name: name,
						factorInstance: .init(
							factorSourceID: factorSourceID,
							publicKey: hdKey.publicKey,
							derivationPath: hdKey.derivationPath
						),
						networkID: networkID
					))
				})))
			}

		case .step1_derivePublicKeys(.delegate(.failedToDerivePublicKey)):
			return .send(.delegate(.createAccountFailed))

		default: return .none
		}
	}
}
