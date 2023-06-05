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
		public let previewResult: TaskResult<ResultFromFeature>
		public var isShowingJSON: Bool = true
		public var isShowingDebugDescription: Bool = true

		public var failure: String? {
			guard case let .failure(error) = previewResult else {
				return nil
			}
			return String(describing: error)
		}

		public var debugDescription: String? {
			guard
				case let .success(success) = previewResult
			else { return nil }
			return String(describing: success)
		}

		public var json: String? {
			@Dependency(\.jsonEncoder) var jsonEncoder
			let encoder = jsonEncoder()
			encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
			guard
				case let .success(success) = previewResult,
				let encodable = success as? Encodable,
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
