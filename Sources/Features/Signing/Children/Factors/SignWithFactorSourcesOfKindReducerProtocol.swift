import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithFactorSourcesOfKindDelegateActionProtocol
protocol SignWithFactorSourcesOfKindDelegateActionProtocol: Sendable, Equatable {
	static func done(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signatures: Set<AccountSignature>
	) -> Self
}

// MARK: - SignWithFactorSourcesOfKindInternalActionProtocol
protocol SignWithFactorSourcesOfKindInternalActionProtocol: Sendable, Equatable {
	static func signingWithFactor(_ signingFactor: SigningFactor) -> Self
}

// MARK: - SignWithFactorSourcesOfKindViewActionProtocol
protocol SignWithFactorSourcesOfKindViewActionProtocol: Sendable, Equatable {
	static var appeared: Self { get }
}

// MARK: - FactorSourceKindSpecifierProtocol
public protocol FactorSourceKindSpecifierProtocol {
	static var factorSourceKind: FactorSourceKind { get }
}

// MARK: - SignWithFactorSourcesOfKindState
public struct SignWithFactorSourcesOfKindState<FactorSourceKindSpecifier: FactorSourceKindSpecifierProtocol>: Sendable, Hashable {
	public let signingFactors: NonEmpty<Set<SigningFactor>>
	public let dataToSign: Data
	public var currentSigningFactor: SigningFactor?
	public init(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		dataToSign: Data,
		currentSigningFactor: SigningFactor? = nil
	) {
		assert(signingFactors.allSatisfy { $0.factorSource.kind == FactorSourceKindSpecifier.factorSourceKind })
		self.signingFactors = signingFactors
		self.dataToSign = dataToSign
		self.currentSigningFactor = currentSigningFactor
	}
}

// MARK: - SignWithFactorSourcesOfKindReducerProtocol
protocol SignWithFactorSourcesOfKindReducerProtocol: Sendable, FeatureReducer, FactorSourceKindSpecifierProtocol where
	DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol,
	State == SignWithFactorSourcesOfKindState<Self>,
	InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol,
	ViewAction: SignWithFactorSourcesOfKindViewActionProtocol
{
	func sign(signingFactor: SigningFactor, state: State) async throws -> Set<AccountSignature>
}

extension SignWithFactorSourcesOfKindReducerProtocol {
	func signWithSigningFactors(of state: State) -> EffectTask<Action> {
		.run { [signingFactors = state.signingFactors] send in
			var allSignatures = Set<AccountSignature>()
			for signingFactor in signingFactors {
				await send(.internal(.signingWithFactor(signingFactor)))
				let signatures = try await sign(signingFactor: signingFactor, state: state)
				allSignatures.append(contentsOf: signatures)
			}
			await send(.delegate(.done(signingFactors: signingFactors, signatures: allSignatures)))
		} catch: { _, _ in
			loggerGlobal.error("Failed to sign with factor source of kind: \(Self.factorSourceKind)")
		}
	}
}
