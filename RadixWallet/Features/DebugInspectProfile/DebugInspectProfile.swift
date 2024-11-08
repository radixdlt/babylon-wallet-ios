import ComposableArchitecture
import SwiftUI

// MARK: - DebugInspectProfile
struct DebugInspectProfile: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Mode: Sendable, Hashable {
			case rawJSON, structured
		}

		var mode: Mode
		let profile: Profile
		init(profile: Profile, mode: Mode = .structured) {
			self.profile = profile
			self.mode = mode
		}

		var json: String? {
			guard
				case let json = profile.profileSnapshot(),
				let jsonString = String(data: json, encoding: .utf8)
			else { return nil }
			return jsonString
		}
	}

	enum ViewAction: Sendable, Equatable {
		case toggleModeButtonTapped
		case copyJSONButtonTapped
	}

	@Dependency(\.pasteboardClient) var pasteboardClient
	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .toggleModeButtonTapped:
			state.mode.toggle()
			return .none
		case .copyJSONButtonTapped:
			if let json = state.json {
				pasteboardClient.copyString(json)
			}
			return .none
		}
	}
}

extension DebugInspectProfile.State.Mode {
	mutating func toggle() {
		switch self {
		case .rawJSON: self = .structured
		case .structured: self = .rawJSON
		}
	}
}
