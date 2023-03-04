import Cryptography
import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, FeatureReducer {
	// MARK: State
	public struct State: Sendable, Hashable {
		public let specifiedNameForNewEntityToCreate: NonEmptyString
		public let factorSources: FactorSources
		public var curve: Slip10Curve

		public init(
			specifiedNameForNewEntityToCreate: NonEmptyString,
			factorSources: FactorSources,
			curve: Slip10Curve = .curve25519 // default to new
		) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
			self.factorSources = factorSources
			self.curve = curve
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmOnDeviceFactorSource
		case selectedCurve(Slip10Curve)
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmedFactorSource(FactorSource, specifiedNameForNewEntityToCreate: NonEmpty<String>, curve: Slip10Curve)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedCurve(selectedCurve):
			state.curve = selectedCurve
			return .none

		case .confirmOnDeviceFactorSource:
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
