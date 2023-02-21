import Cryptography
import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, ReducerProtocol {
	// MARK: State
	public struct State: Sendable, Hashable {
		public let specifiedNameForNewEntityToCreate: NonEmpty<String>
		public let factorSources: FactorSources
		public var curve: Slip10Curve

		public init(
			specifiedNameForNewEntityToCreate: NonEmpty<String>,
			factorSources: FactorSources,
			curve: Slip10Curve = .curve25519 // default to new
		) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
			self.factorSources = factorSources
			self.curve = curve
		}
	}

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .internal(.view(.selectedCurve(selectedCurve))):
			state.curve = selectedCurve
			return .none

		case .internal(.view(.confirmOnDeviceFactorSource)):
			let factorSource = state.factorSources.device
			return .run { [entityName = state.specifiedNameForNewEntityToCreate, curve = state.curve] send in
				await send(.delegate(
					.confirmedFactorSource(
						factorSource,
						specifiedNameForNewEntityToCreate: entityName,
						curve: curve
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
