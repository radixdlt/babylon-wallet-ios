// MARK: - ExpandableTextView
struct ExpandableTextView: View {
	let fullText: String
	let maxLength: Int
	@State private var showFullText: Bool = false
	@State private var displayedText: String

	init(fullText: String, maxLength: Int = 80) {
		self.fullText = fullText
		self.maxLength = maxLength

		if fullText.count > maxLength {
			_displayedText = .init(initialValue: String(fullText.prefix(maxLength)) + "...")
		} else {
			_displayedText = .init(initialValue: fullText)
		}
	}

	private func collapseText() {
		if fullText.count > maxLength {
			displayedText = String(fullText.prefix(maxLength)) + "..."
		} else {
			displayedText = fullText
		}
	}

	private func expandText() {
		displayedText = fullText
	}

	private func toggleText() {
		showFullText.toggle()
		if showFullText {
			expandText()
		} else {
			collapseText()
		}
	}

	var body: some View {
		VStack(alignment: .trailing) {
			Text(displayedText)
				.multilineTextAlignment(.leading)
				.textStyle(.body1HighImportance)
				.foregroundColor(.app.gray1)
				.lineLimit(nil)
				.animation(.easeInOut, value: showFullText)

			if fullText.count > maxLength {
				HStack {
					Spacer()
					Button(showFullText ? "Show Less" : "Show more", action: toggleText)
						.foregroundColor(.blue)
				}
			}
		}
	}
}

// MARK: - ContentView
struct ContentView: View {
	var body: some View {
		ExpandableTextView(fullText: "Your very long text here...", maxLength: 100)
	}
}
