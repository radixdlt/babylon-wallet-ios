// MARK: - ExpandableTextView
/// Based on https://edoardo.fyi/blog/2022/07/swiftui-expandable-text/
/// https://github.com/n3d1117/ExpandableText
struct ExpandableTextView: View {
	private let text: String
	private let lineLimit: Int

	@State private var isExpanded: Bool = false
	@State private var isTruncated: Bool = false
	@State private var intrinsicSize: CGSize = .zero
	@State private var truncatedSize: CGSize = .zero
	@State private var moreTextSize: CGSize = .zero

	private var textStyle: TextStyle = .body1Regular
	private var foregroundColor: Color = .primaryText
	private var textForDisplay: String {
		if isExpanded {
			text + "\n" // Add additional new line to make sure that "Show Less" does not overlay some actual text
		} else {
			text
		}
	}

	init(fullText: String, lineLimit: Int = 3) {
		self.text = fullText
		self.lineLimit = lineLimit
	}

	var body: some View {
		Text(.init(textForDisplay))
			.textStyle(textStyle)
			.foregroundColor(foregroundColor)
			.frame(maxWidth: .infinity, alignment: .leading)
			.lineLimit(isExpanded ? .none : .some(lineLimit))
			.onSizeChanged { size in
				truncatedSize = size
				isTruncated = truncatedSize != intrinsicSize
			}
			.background(
				Text(.init(text)) // Background text used to determine if the text needs to be truncated or not
					.textStyle(textStyle)
					.frame(maxWidth: .infinity, alignment: .leading)
					.lineLimit(nil)
					.fixedSize(horizontal: false, vertical: true)
					.hidden()
					.onSizeChanged { size in
						intrinsicSize = size
						isTruncated = truncatedSize != intrinsicSize
					}
			)
			.applyingTruncationMask(size: moreTextSize, enabled: !isExpanded && isTruncated)
			.background(
				Text(L10n.Common.showMore) // Used to determine the size of the "Show More" text
					.textStyle(.body2Regular)
					.bold()
					.hidden()
					.onSizeChanged { moreTextSize = $0 }
			)
			.overlay(alignment: .trailingLastTextBaseline) {
				if isTruncated || isExpanded {
					Button {
						withAnimation { isExpanded.toggle() }
					} label: {
						Text(isExpanded ? L10n.Common.showLess : L10n.Common.showMore)
							.textStyle(.body2Regular)
							.bold()
							.foregroundColor(.app.blue2)
					}
				}
			}
	}
}

extension ExpandableTextView {
	func textStyle(_ textStyle: TextStyle) -> Self {
		var copy = self
		copy.textStyle = textStyle
		return copy
	}

	func foregroundColor(_ color: Color) -> Self {
		var copy = self
		copy.foregroundColor = color
		return copy
	}
}
