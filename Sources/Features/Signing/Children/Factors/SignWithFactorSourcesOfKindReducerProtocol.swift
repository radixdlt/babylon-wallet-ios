import FactorSourcesClient
import FeaturePrelude

// MARK: - SignWithFactorSourcesOfKindActionProtocol
protocol SignWithFactorSourcesOfKindActionProtocol: Sendable, Equatable {
	static func done(
		signingFactors: NonEmpty<OrderedSet<SigningFactor>>,
		signatures: Set<AccountSignature>
	) -> Self
}

// MARK: - FactorSourceKindSpecifierProtocol
public protocol FactorSourceKindSpecifierProtocol {
	static var factorSourceKind: FactorSourceKind { get }
}

// MARK: - SignWithFactorSourcesOfKindState
public struct SignWithFactorSourcesOfKindState<FactorSourceKindSpecifier: FactorSourceKindSpecifierProtocol>: Sendable, Hashable {
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

// MARK: - SignWithFactorSourcesOfKindReducerProtocol
protocol SignWithFactorSourcesOfKindReducerProtocol: Sendable, FeatureReducer, FactorSourceKindSpecifierProtocol where
	DelegateAction: SignWithFactorSourcesOfKindActionProtocol,
	State == SignWithFactorSourcesOfKindState<Self>
{}
