import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude

public struct SignWithFactorSourcesOfKindDevice: SignWithFactorSourcesOfKindReducerProtocol {
	public typealias Factor = DeviceFactorSource
	public typealias State = SignWithFactorSourcesOfKindState<Factor>
	public enum ViewAction: SignWithFactorSourcesOfKindViewActionProtocol {
		case onFirstTask
	}

	public enum InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol {
		case done(
			signingFactors: NonEmpty<Set<SigningFactor>>,
			signatures: Set<SignatureOfEntity>
		)

		case failedToSign(signingFactor: SigningFactor)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
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
		case let .signingWithFactor(factor):
			state.currentSigningFactor = factor
			return .none
		}
	}

	public func sign(
		signers: SigningFactor.Signers,
		factor deviceFactorSource: Factor,
		state: State
	) async throws -> Set<SignatureOfEntity> {
		try await deviceFactorSourceClient.signUsingDeviceFactorSource(
			deviceFactorSource: deviceFactorSource,
			signerEntities: Set(signers.map(\.entity)),
			unhashedDataToSign: state.signingPurposeWithPayload.dataToSign,
			purpose: .signTransaction(.manifestFromDapp)
		)
	}
}
