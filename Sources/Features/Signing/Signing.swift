import Cryptography
import FactorSourcesClient
import FeaturePrelude
import Profile
import TransactionClient

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID
		public let manifest: TransactionManifest
		public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
		public var factorsOfSigners: FactorsOfSigners?
		public init(
			networkID: NetworkID,
			manifest: TransactionManifest,
			feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
		) {
			self.networkID = networkID
			self.manifest = manifest
			self.feePayerSelectionAmongstCandidates = feePayerSelectionAmongstCandidates
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadRequiredSigners(TaskResult<Set<AccountAddress>>)
		case loadFactorsOfSigners(TaskResult<FactorsOfSigners>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [manifest = state.manifest, networkID = state.networkID] send in
				await send(.internal(.loadRequiredSigners(TaskResult {
					try engineToolkitClient.accountAddressesNeedingToSignTransaction(.init(
						version: .default,
						manifest: manifest,
						networkID: networkID
					))
				})))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadRequiredSigners(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load required signers, error: \(error)")
			return .none

		case let .loadRequiredSigners(.success(accountAddresses)):
			let addresses = Set(accountAddresses + [state.feePayerSelectionAmongstCandidates.selected.account.address])
			return .run { send in
				await send(.internal(.loadFactorsOfSigners(
					TaskResult {
						try await factorSourcesClient.getFactorsOfSigners(addresses)
					}
				)))
			}

		case let .loadFactorsOfSigners(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load factors of signers, error: \(error)")
			return .none

		case let .loadFactorsOfSigners(.success(factorsOfSigners)):
			state.factorsOfSigners = factorsOfSigners

			return .none
		}
	}
}
