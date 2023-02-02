import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, ReducerProtocol {
	public init() {}
}

public extension SelectGenesisFactorSource {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.confirmOnDeviceFactorSource)):
			let factorSource = state.factorSources.first(where: { $0.any().factorSourceKind == .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind })!
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
