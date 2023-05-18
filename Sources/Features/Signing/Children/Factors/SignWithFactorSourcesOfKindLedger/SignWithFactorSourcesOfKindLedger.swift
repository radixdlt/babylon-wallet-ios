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
		case onFirstTask
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
		case .onFirstTask:
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

	public func sign(
		signingFactor: SigningFactor,
		state: State
	) async throws -> Set<SignatureOfEntity> {
		let ledger = try LedgerFactorSource(factorSource: signingFactor.factorSource)
		let signers = signingFactor.signers

		switch state.signingPurposeWithPayload {
		case let .signTransaction(_, compiledIntent, _):
			let dataToSign = Data(compiledIntent.compiledIntent)
			do {
				let expectedHash = try blake2b(data: dataToSign)
				loggerGlobal.notice("\n\nExpected TX hash: \(expectedHash.hex)\n\n")
			} catch {
				loggerGlobal.critical("Failed to hash: \(error)")
			}
			let ledgerTXDisplayMode: FactorSource.LedgerHardwareWallet.SigningDisplayMode = await appPreferencesClient.getPreferences().display.ledgerHQHardwareWalletSigningDisplayMode

			return try await ledgerHardwareWalletClient.signTransaction(.init(
				ledger: ledger,
				signers: signers,
				unhashedDataToSign: dataToSign,
				ledgerTXDisplayMode: ledgerTXDisplayMode.mode,
				displayHashOnLedgerDisplay: true
			))
		case let .signAuth(authToSign):
			do {
				let expectedHash = try blake2b(data: authToSign.payloadToHashAndSign)
				loggerGlobal.notice("\n\nExpected TX hash: \(expectedHash.hex)\n\n")
			} catch {
				loggerGlobal.critical("Failed to hash: \(error)")
			}

			return try await ledgerHardwareWalletClient.signAuthChallenge(.init(
				ledger: ledger,
				signers: signers,
				challenge: authToSign.input.challenge,
				origin: authToSign.input.origin,
				dAppDefinitionAddress: authToSign.input.dAppDefinitionAddress
			))
		}
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
