import FactorSourcesClient
import FeaturePrelude
import UseFactorSourceClient

public struct SignWithFactorSourcesOfKindDevice: SignWithFactorSourcesOfKindReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.device
	public typealias State = SignWithFactorSourcesOfKindState<Self>
	public enum ViewAction: SignWithFactorSourcesOfKindViewActionProtocol {
		case appeared
	}

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(
			signingFactors: NonEmpty<Set<SigningFactor>>,
			signatures: Set<AccountSignature>
		)
	}

	@Dependency(\.useFactorSourceClient) var useFactorSourceClient
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
		case let .signingWithFactor(factor):
			state.currentSigningFactor = factor
			return .none
		}
	}

	func sign(
		signingFactor: SigningFactor,
		state: State
	) async throws -> Set<AccountSignature> {
		try await useFactorSourceClient.signUsingDeviceFactorSource(
			deviceFactorSource: signingFactor.factorSource,
			of: Set(signingFactor.signers.map(\.account)),
			unhashedDataToSign: state.dataToSign,
			purpose: .signData(isTransaction: true)
		)
	}
}
