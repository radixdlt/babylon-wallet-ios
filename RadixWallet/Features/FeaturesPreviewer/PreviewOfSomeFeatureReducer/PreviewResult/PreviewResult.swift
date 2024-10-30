import ComposableArchitecture
import SwiftUI

// MARK: - PreviewResult
struct PreviewResult<ResultFromFeature>: FeatureReducer where ResultFromFeature: Hashable & Sendable {
	enum ViewAction: Sendable, Hashable {
		case restart
		case showJSONToggled(Bool)
		case showDebugDescriptionToggled(Bool)
	}

	enum DelegateAction: Sendable, Hashable {
		case restart
	}

	struct State: Sendable, Hashable {
		let previewResult: TaskResult<ResultFromFeature>
		var isShowingJSON: Bool = true
		var isShowingDebugDescription: Bool = true

		var failure: String? {
			guard case let .failure(error) = previewResult else {
				return nil
			}
			return String(describing: error)
		}

		var debugDescription: String? {
			guard
				case let .success(success) = previewResult
			else { return nil }
			return String(describing: success)
		}

		var json: String? {
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

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
