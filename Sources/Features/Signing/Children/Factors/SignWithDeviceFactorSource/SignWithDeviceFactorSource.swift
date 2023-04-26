import FactorSourcesClient
import FeaturePrelude
import UseFactorSourceClient

// MARK: - SignWithFactorReducerActionProtocol
protocol SignWithFactorReducerActionProtocol: Sendable, Equatable {
	static func done(signingFactor: SigningFactor, signatures: Set<AccountSignature>) -> Self
}

// MARK: - FactorSourceKindSpecifierProtocol
// protocol SignWithFactorReducerStateProtocol: Sendable, Hashable {
//    init(signingFactor: SigningFactor, dataToSign: Data)
// }

public protocol FactorSourceKindSpecifierProtocol {
	static var factorSourceKind: FactorSourceKind { get }
}

// MARK: - SignWithFactorState
public struct SignWithFactorState<FactorSourceKindSpecifier: FactorSourceKindSpecifierProtocol>: Sendable, Hashable {
	public let signingFactor: SigningFactor
	public let dataToSign: Data
	public init(signingFactor: SigningFactor, dataToSign: Data) {
		assert(signingFactor.factorSource.kind == FactorSourceKindSpecifier.factorSourceKind)
		self.signingFactor = signingFactor
		self.dataToSign = dataToSign
	}
}

// MARK: - SignWithFactorReducerProtocol
protocol SignWithFactorReducerProtocol: Sendable, FeatureReducer, FactorSourceKindSpecifierProtocol where
	DelegateAction: SignWithFactorReducerActionProtocol,
	State == SignWithFactorState<Self>
{}

// MARK: - SignWithDeviceFactorSource
// extension SignWithFactorReducerProtocol {
//    public typealias State = SignWithFactorState<Self>
// }

public struct SignWithDeviceFactorSource: SignWithFactorReducerProtocol {
	public static let factorSourceKind = FactorSourceKind.device
	public typealias State = SignWithFactorState<Self>
	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: SignWithFactorReducerActionProtocol {
		case done(signingFactor: SigningFactor, signatures: Set<AccountSignature>)
	}

	@Dependency(\.useFactorSourceClient) var useFactorSourceClient
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [signingFactor = state.signingFactor, data = state.dataToSign] send in
				let signatures = try await useFactorSourceClient.signUsingDeviceFactorSource(
					of: Set(signingFactor.signers.map(\.account)),
					unhashedDataToSign: data
				)
				//                await send(.internal(.signedWith(factorSource: factorSource, signatures: signatures)))
				await send(.delegate(.done(signingFactor: signingFactor, signatures: signatures)))
			} catch: { _, _ in
				loggerGlobal.error("Failed to device sign")
			}
		}
	}
}
