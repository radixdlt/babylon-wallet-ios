import FeaturePrelude

public struct EditPersonaEntry<ID: EditPersonaFieldID>: Sendable, FeatureReducer {
	public typealias State = EditPersonaField<ID>.State

	public enum ChildAction: Sendable, Equatable {
		case field(EditPersonaField<ID>.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \.self,
			action: /Action.child .. EditPersonaEntry<ID>.ChildAction.field
		) {
			EditPersonaField()
		}
	}
}
