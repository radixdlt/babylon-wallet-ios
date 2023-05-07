import AppPreferencesClient
import EngineToolkit
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient

// MARK: - SignWithFactorSourcesOfKindLedger
public struct SignWithFactorSourcesOfKindLedger: SignWithFactorSourcesOfKindReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.ledgerHQHardwareWallet
	public typealias State = SignWithFactorSourcesOfKindState<Self>

	public enum ViewAction: SignWithFactorSourcesOfKindViewActionProtocol {
		case appeared
	}

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(signingFactors: NonEmpty<Set<SigningFactor>>, signatures: Set<SignatureOfEntity>)
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return signWithSigningFactors(of: state)
		}
	}

	public func reduce(
		into state: inout State,
		internalAction: InternalAction
	) -> EffectTask<Action> {
		switch internalAction {
		case let .signingWithFactor(currentLedger):
			state.currentSigningFactor = currentLedger
			return .none
		}
	}

	public func sign(signingFactor: SigningFactor, state: State) async throws -> Set<SignatureOfEntity> {
		do {
			let expectedHash = try blake2b(data: state.dataToSign)
			loggerGlobal.notice("\n\nExpected hash: \(expectedHash.hex)\n\n")
		} catch {
			loggerGlobal.critical("Failed to hash: \(error)")
		}
		let ledgerTXDisplayMode: FactorSource.LedgerHardwareWallet.SigningDisplayMode = await appPreferencesClient.getPreferences().display.ledgerHQHardwareWalletSigningDisplayMode
		return try await ledgerHardwareWalletClient.sign(.init(
			signingFactor: signingFactor,
			unhashedDataToSign: state.dataToSign,
			ledgerTXDisplayMode: ledgerTXDisplayMode.mode,
			displayHashOnLedgerDisplay: true
		))
	}
}

extension FactorSource.LedgerHardwareWallet.SigningDisplayMode {
	// seperation so that we do not accidentally break profile or RadixConnect
	var mode: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.SignTransaction.Mode {
		switch self {
		case .verbose: return .verbose
		case .summary: return .summary
		}
	}
}
