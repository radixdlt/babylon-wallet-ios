import ComposableArchitecture
import SwiftUI

public struct SignWithFactorSourcesOfKindDevice: SignWithFactorSourcesOfKindReducer {
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

		case failedToSign(SigningFactor)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: /Action.child .. ChildAction.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			signWithSigningFactors(of: state)
		default:
			.none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			signWithSigningFactors(of: state)
		}
	}

	public func reduce(
		into state: inout State,
		internalAction: InternalAction
	) -> Effect<Action> {
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
		let dataToSign: Data = switch state.signingPurposeWithPayload {
		case let .signAuth(auth): try blake2b(data: auth.payloadToHashAndSign)
		case let .signTransaction(_, intent, _):
			try intent.intentHash().bytes().data
		}

		return try await deviceFactorSourceClient.signUsingDeviceFactorSource(
			deviceFactorSource: deviceFactorSource,
			signerEntities: Set(signers.map(\.entity)),
			hashedDataToSign: dataToSign,
			purpose: .signTransaction(.manifestFromDapp)
		)
	}
}
