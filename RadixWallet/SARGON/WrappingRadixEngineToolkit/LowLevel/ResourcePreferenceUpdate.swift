import Foundation

// MARK: - ResourcePreference
public enum ResourcePreference: DummySargon {
	case allowed
	case disallowed
}

// MARK: - ResourcePreferenceUpdate
public enum ResourcePreferenceUpdate: DummySargon {
	case set(value: ResourcePreference)
	case remove
}
