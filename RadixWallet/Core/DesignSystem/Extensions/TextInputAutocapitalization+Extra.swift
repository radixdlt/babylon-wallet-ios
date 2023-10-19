
#if os(iOS)
public enum EquatableTextInputCapitalization: Equatable {
	case never
	case words
	case sentences
	case characters

	public var rawValue: TextInputAutocapitalization {
		switch self {
		case .never: .never
		case .words: .words
		case .sentences: .sentences
		case .characters: .characters
		}
	}
}
#endif
