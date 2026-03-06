
struct LabelledDate: View {
	let label: String
	let date: Date

	var body: some View {
		HStack(spacing: .small3) {
			Text(label)
				.textStyle(.body2Header)

			Text(date.formatted(dateFormat))
				.textStyle(.body2Regular)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.foregroundColor(.secondaryText)
	}

	private let dateFormat: Date.FormatStyle = .dateTime.day().month(.wide).year()
}
