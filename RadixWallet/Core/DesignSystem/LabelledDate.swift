
struct LabelledDate: View {
	let label: String
	let date: Date

	init(label: String, date: Date) {
		self.label = label
		self.date = date
	}

	var body: some View {
		HStack(spacing: .small3) {
			Text(label)
				.textStyle(.body2Header)

			Text(date.formatted(dateFormat))
				.textStyle(.body2Regular)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.foregroundColor(.app.gray2)
	}

	private let dateFormat: Date.FormatStyle = .dateTime.day().month(.wide).year()
}
