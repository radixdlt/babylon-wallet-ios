import FeaturePrelude
import Profile

// MARK: - DebugInspectProfile
public struct DebugInspectProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case rawJSON, structured
		}

		public var mode: Mode
		public let profile: Profile
		public init(profile: Profile, mode: Mode = .structured) {
			self.profile = profile
			self.mode = mode
		}

		public var json: String? {
			@Dependency(\.jsonEncoder) var jsonEncoder
			let encoder = jsonEncoder()
			encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
			guard
				let json = try? encoder.encode(profile.snapshot()),
				let jsonString = String(data: json, encoding: .utf8)
			else { return nil }
			return jsonString
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case toggleModeButtonTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .toggleModeButtonTapped:
			state.mode.toggle()
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
