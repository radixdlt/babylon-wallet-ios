import FeaturePrelude

// MARK: - NewStructure
public struct NewStructure: Sendable, Hashable {
	/// Confirmation role
	public var newPhoneConfirmer: FactorSource?

	/// Recovery role
	public var lostPhoneHelper: FactorSource?

	public init(newPhoneConfirmer: FactorSource? = nil, lostPhoneHelper: FactorSource? = nil) {
		self.newPhoneConfirmer = newPhoneConfirmer
		self.lostPhoneHelper = lostPhoneHelper
	}
}

// MARK: - SimpleCreateSecurityStructureFlow
public struct SimpleCreateSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var structure: NewStructure
		public init(structure: NewStructure = .init()) {
			self.structure = structure
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectPhoneConfirmer
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectPhoneConfirmer:
			loggerGlobal.debug("Select phone clicked")
			return .none
		}
	}
}
