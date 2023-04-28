import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithFactorReducerActionProtocol
protocol SignWithFactorReducerActionProtocol: Sendable, Equatable {
	static func done(signingFactor: SigningFactor, signatures: Set<AccountSignature>) -> Self
}

// MARK: - FactorSourceKindSpecifierProtocol
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
