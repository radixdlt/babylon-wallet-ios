import SwiftUI

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
public enum EquatableTextInputCapitalization: Equatable {
	case never
	case words
	case sentences
	case characters

	public var rawValue: TextInputAutocapitalization {
		switch self {
		case .never: return .never
		case .words: return .words
		case .sentences: return .sentences
		case .characters: return .characters
		}
	}
}
