import FeaturePrelude

// MARK: - EditPersonaName
public struct EditPersonaName: FeatureReducer, EmptyInitializable {
	public struct State: Sendable, Hashable {
		var family: EditPersonaDynamicField.State
		var given: EditPersonaDynamicField.State
		var nickName: EditPersonaDynamicField.State
		var variant: PersonaData.Name.Variant

		init(
			with name: PersonaData.Name,
			isRequestedByDapp: Bool
		) {
			self.family = EditPersonaDynamicField.State(
				id: .familyName,
				text: name.family,
				isRequiredByDapp: isRequestedByDapp,
				showsName: true
			)
			self.given = EditPersonaDynamicField.State(
				id: .givenNames,
				text: name.given,
				isRequiredByDapp: isRequestedByDapp,
				showsName: true
			)

			self.nickName = EditPersonaDynamicField.State(
				id: .nickName,
				text: name.middle,
				isRequiredByDapp: isRequestedByDapp,
				showsName: true
			)

			self.variant = name.variant
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case variantPick(PersonaData.Name.Variant)
	}

	public enum ChildAction: Sendable, Equatable {
		case family(EditPersonaDynamicField.Action)
		case given(EditPersonaDynamicField.Action)
		case nickname(EditPersonaDynamicField.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \.family,
			action: /Action.child .. ChildAction.family,
			child: EditPersonaField.init
		)
		Scope(
			state: \.given,
			action: /Action.child .. ChildAction.given,
			child: EditPersonaField.init
		)

		Scope(
			state: \.nickName,
			action: /Action.child .. ChildAction.nickname,
			child: EditPersonaField.init
		)

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .variantPick(variant):
			state.variant = variant
			return .none
		}
	}
}
