import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithFactorReducerActionProtocol
protocol SignWithFactorReducerActionProtocol: Sendable, Equatable {
	static func done(
		signingFactors: NonEmpty<OrderedSet<SigningFactor>>,
		signatures: Set<AccountSignature>
	) -> Self
}

// MARK: - FactorSourceKindSpecifierProtocol
public protocol FactorSourceKindSpecifierProtocol {
	static var factorSourceKind: FactorSourceKind { get }
}

// MARK: - SignWithFactorState
public struct SignWithFactorState<FactorSourceKindSpecifier: FactorSourceKindSpecifierProtocol>: Sendable, Hashable {
	public let signingFactors: NonEmpty<OrderedSet<SigningFactor>>
	public let dataToSign: Data
	public var currentSigningFactor: SigningFactor?
	public init(
		signingFactors: NonEmpty<OrderedSet<SigningFactor>>,
		dataToSign: Data,
		currentSigningFactor: SigningFactor? = nil
	) {
		assert(signingFactors.allSatisfy { $0.factorSource.kind == FactorSourceKindSpecifier.factorSourceKind })
		self.signingFactors = signingFactors
		self.dataToSign = dataToSign
		self.currentSigningFactor = currentSigningFactor
	}
}

// MARK: - SignWithFactorReducerProtocol
protocol SignWithFactorReducerProtocol: Sendable, FeatureReducer, FactorSourceKindSpecifierProtocol where
	DelegateAction: SignWithFactorReducerActionProtocol,
	State == SignWithFactorState<Self>
{}
