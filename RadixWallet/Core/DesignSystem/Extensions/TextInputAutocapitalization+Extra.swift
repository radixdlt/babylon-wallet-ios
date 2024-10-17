
#if os(iOS)
enum EquatableTextInputCapitalization: Equatable {
	case never
	case words
	case sentences
	case characters

	var rawValue: TextInputAutocapitalization {
		switch self {
		case .never: .never
		case .words: .words
		case .sentences: .sentences
		case .characters: .characters
		}
	}
}
#endif
