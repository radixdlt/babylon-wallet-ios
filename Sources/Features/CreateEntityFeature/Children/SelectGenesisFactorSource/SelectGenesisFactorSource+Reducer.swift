import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, ReducerProtocol {
	// MARK: State
	public struct State: Sendable, Hashable {
		public let specifiedNameForNewEntityToCreate: NonEmpty<String>
		public let factorSources: FactorSources

		public init(
			specifiedNameForNewEntityToCreate: NonEmpty<String>,
			factorSources: FactorSources
		) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
			self.factorSources = factorSources
		}
	}

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.confirmOnDeviceFactorSource)):
//			let factorSource = state.factorSources.first(where: { $0.any().factorSourceKind == .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind })?.any() as! FactorSource
			let factorSource = state.factorSources.first(where: { $0.kind == .device })!
			return .run { [entityName = state.specifiedNameForNewEntityToCreate] send in
				await send(.delegate(
					.confirmedFactorSource(
						factorSource,
						specifiedNameForNewEntityToCreate: entityName
					))
				)
			}
		case .delegate: return .none
		}
	}
}

#if DEBUG
extension SelectGenesisFactorSource.State {
	public static let previewValue: Self = .init(
		specifiedNameForNewEntityToCreate: "preview",
		factorSources: .previewValue
	)
}
#endif
