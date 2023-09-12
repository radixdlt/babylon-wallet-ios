import FeaturePrelude

// MARK: - EditPersonaName
public struct EditPersonaName: FeatureReducer, EmptyInitializable {
	public struct State: Sendable, Hashable {
		let id: PersonaDataEntryID
		var family: EditPersonaDynamicField.State
		var given: EditPersonaDynamicField.State
		var nickName: EditPersonaDynamicField.State
		var variant: PersonaData.Name.Variant

		init(
			entryID: PersonaDataEntryID?,
			with name: PersonaData.Name,
			isRequestedByDapp: Bool
		) {
			@Dependency(\.uuid) var uuid
			self.id = entryID ?? uuid()
			self.family = EditPersonaDynamicField.State(
				behaviour: .familyName,
				entryID: id, // Uh.. terrible, but we are gonne refactor this whole thing anyway
				text: name.familyName,
				isRequiredByDapp: isRequestedByDapp,
				showsTitle: true
			)
			self.given = EditPersonaDynamicField.State(
				behaviour: .givenNames,
				entryID: id, // Uh.. terrible, but we are gonne refactor this whole thing anyway
				text: name.givenNames,
				isRequiredByDapp: isRequestedByDapp,
				showsTitle: true
			)
			self.nickName = EditPersonaDynamicField.State(
				behaviour: .nickName,
				entryID: id, // Uh.. terrible, but we are gonne refactor this whole thing anyway
				text: name.nickname,
				isRequiredByDapp: isRequestedByDapp,
				showsTitle: true
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

	public var body: some ReducerOf<Self> {
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .variantPick(variant):
			state.variant = variant
			return .none
		}
	}
}
