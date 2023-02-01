import FeaturePrelude
import GatherFactorsFeature

// MARK: - NameNewEntity.State
public extension NameNewEntity {
	struct State: Sendable, Equatable {
		public var isFirst: Bool
		public var inputtedName: String
		public var sanitizedName: String { inputtedName.trimmed() }

		@BindingState public var focusedField: Field?

		public init(
			isFirst: Bool,
			inputtedEntityName: String = "",
			focusedField: Field? = nil
		) {
			self.inputtedName = inputtedEntityName
			self.focusedField = focusedField
			self.isFirst = isFirst
		}
	}
}

// MARK: - NameNewEntity.State.Field
public extension NameNewEntity.State {
	enum Field: String, Sendable, Hashable {
		case accountName
	}
}
