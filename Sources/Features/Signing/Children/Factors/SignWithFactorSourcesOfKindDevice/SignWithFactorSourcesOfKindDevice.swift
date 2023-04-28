import FactorSourcesClient
import FeaturePrelude
import UseFactorSourceClient

public struct SignWithFactorSourcesOfKindDevice: SignWithFactorSourcesOfKindReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.device
	public typealias State = SignWithFactorSourcesOfKindState<Self>
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case signingWithFactor(SigningFactor)
	}

	public enum DelegateAction: SignWithFactorSourcesOfKindActionProtocol {
		case done(
			signingFactors: NonEmpty<OrderedSet<SigningFactor>>,
			signatures: Set<AccountSignature>
		)
	}

	@Dependency(\.useFactorSourceClient) var useFactorSourceClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [signingFactors = state.signingFactors, data = state.dataToSign] send in
				var signaturesFromAllFactorSources = Set<AccountSignature>()
				for signingFactor in signingFactors {
					await send(.internal(.signingWithFactor(signingFactor)))
					let signatures = try await useFactorSourceClient.signUsingDeviceFactorSource(deviceFactorSource: signingFactor.factorSource, of: Set(signingFactor.signers.map(\.account)), unhashedDataToSign: data)
					for signature in signatures {
						signaturesFromAllFactorSources.insert(signature)
					}
				}
				await send(.delegate(.done(signingFactors: signingFactors, signatures: signaturesFromAllFactorSources)))

			} catch: { _, _ in
				loggerGlobal.error("Failed to device sign")
			}
		}
	}

	public func reduce(
		into state: inout SignWithFactorSourcesOfKindState<SignWithFactorSourcesOfKindDevice>,
		internalAction: InternalAction
	) -> EffectTask<Action> {
		switch internalAction {
		case let .signingWithFactor(factor):
			state.currentSigningFactor = factor
			return .none
		}
	}
}
