import SwiftUI

#if os(iOS)
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
#endif
