import FeaturePrelude

// MARK: - NewStructure
public struct NewStructure: Sendable, Hashable {
	/// Confirmation role
	public var newPhoneConfirmer: SecurityQuestionsFactorSource?

	/// Recovery role
	public var lostPhoneHelper: TrustedContactFactorSource?

	public init(newPhoneConfirmer: SecurityQuestionsFactorSource? = nil, lostPhoneHelper: TrustedContactFactorSource? = nil) {
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
		case selectNewPhoneConfirmer
		case selectLostPhoneHelper
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectNewPhoneConfirmer
		case selectLostPhoneHelper
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectNewPhoneConfirmer:
			loggerGlobal.debug("'New phone confirmer' tapped")
			return .send(.delegate(.selectNewPhoneConfirmer))

		case .selectLostPhoneHelper:
			loggerGlobal.debug("'Lost phone helper' button tapped")
			return .send(.delegate(.selectLostPhoneHelper))
		}
	}
}
