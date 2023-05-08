import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude

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
			signatures: Set<SignatureOfEntity>
		)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
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
	) async throws -> Set<SignatureOfEntity> {
		try await deviceFactorSourceClient.signUsingDeviceFactorSource(
			deviceFactorSource: signingFactor.factorSource,
			signerEntities: Set(signingFactor.signers.map(\.entity)),
			unhashedDataToSign: state.dataToSign,
			purpose: .signTransaction(.manifestFromDapp)
		)
	}
}
