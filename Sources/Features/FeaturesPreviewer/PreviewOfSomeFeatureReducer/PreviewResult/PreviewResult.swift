import FeaturePrelude

// MARK: - PreviewResult
public struct PreviewResult<ResultFromFeature>: FeatureReducer where ResultFromFeature: Hashable & Sendable {
	public enum ViewAction: Sendable, Hashable {
		case restart
		case showJSONToggled(Bool)
		case showDebugDescriptionToggled(Bool)
	}

	public enum DelegateAction: Sendable, Hashable {
		case restart
	}

	public struct State: Sendable, Hashable {
		public let previewResult: ResultFromFeature
		public var isShowingJSON: Bool = true
		public var isShowingDebugDescription: Bool = true

		public var json: String? {
			@Dependency(\.jsonEncoder) var jsonEncoder
			let encoder = jsonEncoder()
			encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
			guard
				let encodable = previewResult as? Encodable,
				let json = try? encoder.encode(encodable),
				let jsonString = String(data: json, encoding: .utf8)
			else { return nil }
			return jsonString
		}
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .showJSONToggled(showJSON):
			state.isShowingJSON = showJSON
			return .none

		case let .showDebugDescriptionToggled(showDebugDescription):
			state.isShowingDebugDescription = showDebugDescription
			return .none

		case .restart:
			return .send(.delegate(.restart))
		}
	}
}
