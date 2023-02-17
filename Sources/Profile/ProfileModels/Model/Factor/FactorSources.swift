import Prelude

public typealias FactorSources = NonEmpty<IdentifiedArrayOf<FactorSource>>

#if DEBUG
extension FactorSources {
	public init(_ factorSource: FactorSource) {
		self.init(uniqueElements: [factorSource])
	}

	public init(uniqueElements: some Swift.Collection<FactorSource>) {
		precondition(!uniqueElements.isEmpty)
		self.init(rawValue: .init(uniqueElements: uniqueElements))!
	}

	public static let previewValue: Self = fixMultifactor()
}

#endif // DEBUG
