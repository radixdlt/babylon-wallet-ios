import ComposableArchitecture
import SwiftUI

// MARK: - SignWithFactorSourcesOfKindDelegateActionProtocol
protocol SignWithFactorSourcesOfKindDelegateActionProtocol: Sendable, Equatable {
	static func done(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signatures: Set<SignatureOfEntity>
	) -> Self

	static func failedToSign(_ signingFactor: SigningFactor) -> Self
}

// MARK: - SignWithFactorSourcesOfKindInternalActionProtocol
protocol SignWithFactorSourcesOfKindInternalActionProtocol: Sendable, Equatable {
	static func signingWithFactor(_ signingFactor: SigningFactor) -> Self
}

// MARK: - SignWithFactorSourcesOfKindChildActionProtocol
protocol SignWithFactorSourcesOfKindChildActionProtocol: Sendable, Equatable {
	static func factorSourceAccess(_: FactorSourceAccess.Action) -> Self
}

// MARK: - SignWithFactorSourcesOfKindState
public struct SignWithFactorSourcesOfKindState<Factor: FactorSourceProtocol>:
	Sendable,
	Hashable
{
	public let signingFactors: NonEmpty<Set<SigningFactor>>
	public let signingPurposeWithPayload: SigningPurposeWithPayload
	public var currentSigningFactor: SigningFactor?
	public var factorSourceAccess: FactorSourceAccess.State

	public init(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signingPurposeWithPayload: SigningPurposeWithPayload,
		currentSigningFactor: SigningFactor? = nil,
		factorSourceAccess: FactorSourceAccess.State
	) {
		assert(signingFactors.allSatisfy { $0.factorSource.kind == Factor.kind })
		self.signingFactors = signingFactors
		self.signingPurposeWithPayload = signingPurposeWithPayload
		self.currentSigningFactor = currentSigningFactor
		self.factorSourceAccess = factorSourceAccess
	}
}

// MARK: - SignWithFactorSourcesOfKindReducer
protocol SignWithFactorSourcesOfKindReducer:
	Sendable,
	FeatureReducer
	where
	DelegateAction: SignWithFactorSourcesOfKindDelegateActionProtocol,
	State == SignWithFactorSourcesOfKindState<Factor>,
	InternalAction: SignWithFactorSourcesOfKindInternalActionProtocol,
	ChildAction: SignWithFactorSourcesOfKindChildActionProtocol
{
	associatedtype Factor: FactorSourceProtocol

	func sign(
		signers: SigningFactor.Signers,
		factor: Factor,
		state: State
	) async throws -> Set<SignatureOfEntity>
}

extension SignWithFactorSourcesOfKindReducer {
	func signWithSigningFactors(of state: State) -> Effect<Action> {
		.run { [signingFactors = state.signingFactors] send in
			var allSignatures = Set<SignatureOfEntity>()
			for signingFactor in signingFactors {
				await send(.internal(.signingWithFactor(signingFactor)))

				do {
					let signatures = try await sign(
						signers: signingFactor.signers,
						factor: signingFactor.factorSource.extract(as: Factor.self),
						state: state
					)
					allSignatures.append(contentsOf: signatures)
				} catch {
					await send(.delegate(.failedToSign(signingFactor)))
					break
				}
			}
			await send(.delegate(.done(signingFactors: signingFactors, signatures: allSignatures)))
		}
	}
}
