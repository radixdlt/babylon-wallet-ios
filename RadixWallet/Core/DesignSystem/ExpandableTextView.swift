// MARK: - ExpandableTextView
struct ExpandableTextView: View {
	/// The full text to be displayed
	private let fullText: String
	/// The text length for collapsed state
	private let collapsedTextLength: Int

	@State private var showFullText: Bool = false
	@State private var displayedText: String

	init(fullText: String, collapsedTextLength: Int) {
		self.fullText = fullText
		self.collapsedTextLength = collapsedTextLength

		if fullText.count > collapsedTextLength {
			_displayedText = .init(initialValue: String(fullText.prefix(collapsedTextLength)) + "...")
		} else {
			_displayedText = .init(initialValue: fullText)
		}
	}

	private func toggleText() {
		showFullText.toggle()
		if showFullText {
			displayedText = fullText
		} else {
			displayedText = String(fullText.prefix(collapsedTextLength)) + "..."
		}
	}

	var body: some View {
		VStack(alignment: .leading) {
			Text(displayedText)
				.multilineTextAlignment(.leading)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
				.lineLimit(nil)
				.animation(.easeInOut, value: showFullText)

			if fullText.count > collapsedTextLength {
				HStack {
					Spacer()
					Button(showFullText ? L10n.Common.showLess : L10n.Common.showMore, action: toggleText)
						.foregroundColor(.app.blue2)
				}
			}
		}
	}
}
