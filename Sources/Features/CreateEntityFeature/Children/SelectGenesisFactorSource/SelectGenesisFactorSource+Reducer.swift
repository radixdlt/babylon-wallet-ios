import Cryptography
import FeaturePrelude

// MARK: - SelectGenesisFactorSource
public struct SelectGenesisFactorSource: Sendable, FeatureReducer {
	// MARK: State
	public struct State: Sendable, Hashable {
		public let specifiedNameForNewEntityToCreate: NonEmptyString
		public let factorSources: FactorSources
		public var selectedFactorSource: FactorSource
		public var selectedCurve: Slip10Curve

		public init(
			specifiedNameForNewEntityToCreate: NonEmptyString,
			factorSources: FactorSources,
			selectedCurve: Slip10Curve = .curve25519 // default to new
		) {
			self.specifiedNameForNewEntityToCreate = specifiedNameForNewEntityToCreate
			self.factorSources = factorSources
			self.selectedFactorSource = factorSources.first
			self.selectedCurve = selectedCurve
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmOnDeviceFactorSource
		case selectedFactorSource(FactorSource)
		case selectedCurve(Slip10Curve)
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmedFactorSource(FactorSource, specifiedNameForNewEntityToCreate: NonEmpty<String>, curve: Slip10Curve)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedFactorSource(selectedFactorSource):
			state.selectedFactorSource = selectedFactorSource
			if !selectedFactorSource.parameters.supportedCurves.contains(state.selectedCurve) {
				state.selectedCurve = selectedFactorSource.parameters.supportedCurves.first
			}
			return .none

		case let .selectedCurve(selectedCurve):
			precondition(state.selectedFactorSource.parameters.supportedCurves.contains(selectedCurve))
			state.selectedCurve = selectedCurve
			return .none

		case .confirmOnDeviceFactorSource:
			let factorSource = state.factorSources.device
			return .run { [entityName = state.specifiedNameForNewEntityToCreate, selectedCurve = state.selectedCurve] send in
				await send(.delegate(
					.confirmedFactorSource(
						factorSource,
						specifiedNameForNewEntityToCreate: entityName,
						curve: selectedCurve
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
