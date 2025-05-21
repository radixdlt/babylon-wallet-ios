// MARK: - SelectionList
struct SelectionList<Choices: Sequence>: View where Choices.Element: Hashable {
	@Environment(\.colorScheme) private var colorScheme
	typealias Element = Choices.Element

	let choices: Choices
	let title: (Element) -> String
	@Binding
	var selection: [Element]?
	let requirement: SelectionRequirement

	init(
		_ choices: Choices,
		title: @escaping (Element) -> String,
		selection: Binding<[Element]?>,
		requiring requirement: SelectionRequirement
	) {
		self.choices = choices
		self.title = title
		self._selection = selection
		self.requirement = requirement
	}

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				Selection($selection, from: choices, requiring: requirement) { item in
					Button(action: item.action) {
						HStack(spacing: 0) {
							Text(title(item.value))
								.textStyle(.body1HighImportance)
								.foregroundColor(.primaryText)
							Spacer()
							// Need to disable, since broken in swiftformat 0.52.7
							// swiftformat:disable redundantClosure
							Group {
								if requirement == .exactly(1) {
									RadioButton(
										appearance: colorScheme == .light ? .dark : .light,
										isSelected: item.isSelected
									)
								} else {
									CheckmarkView(
										appearance: colorScheme == .light ? .dark : .light,
										isChecked: item.isSelected
									)
								}
							}
							.padding(.trailing, .small3)
							.opacity(item.isDisabled ? 0.3 : 1)
							// swiftformat:enable redundantClosure
						}
						.padding(.vertical, .medium3)
					}
					.buttonStyle(.inert)
					.separator(.bottom)
				}
			}
			.padding(.horizontal, .medium3)
		}
	}
}

#if DEBUG
struct SelectionList_PreviewProvider: PreviewProvider {
	static var previews: some View {
		SelectionList_Preview(requirement: .exactly(0)).previewDisplayName("Exactly 0")
		SelectionList_Preview(requirement: .exactly(1)).previewDisplayName("Exactly 1")
		SelectionList_Preview(requirement: .exactly(2)).previewDisplayName("Exactly 2")

		SelectionList_Preview(requirement: .atLeast(0)).previewDisplayName("At least 0")
		SelectionList_Preview(requirement: .atLeast(1)).previewDisplayName("At least 1")
		SelectionList_Preview(requirement: .atLeast(2)).previewDisplayName("At least 2")
	}
}

struct SelectionList_Preview: View {
	@State
	var selection: [Int]? = nil
	let requirement: SelectionRequirement

	var body: some View {
		SelectionList(
			1 ... 10,
			title: String.init,
			selection: $selection,
			requiring: requirement
		)
		.footer {
			if let selection {
				Text("Result: \(String(describing: selection))")
			} else {
				Text("Result: nil")
			}
			WithControlRequirements(selection, forAction: { loggerGlobal.debug("\(String(describing: $0))") }) { action in
				Button("Continue", action: action).buttonStyle(.primaryRectangular)
			}
		}
	}
}
#endif
