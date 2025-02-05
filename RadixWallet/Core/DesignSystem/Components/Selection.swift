// MARK: - SelectionItem
struct SelectionItem<Value> {
	let value: Value
	var isSelected: Bool
	var isDisabled: Bool
	var action: @Sendable () -> Void
}

// MARK: Sendable
extension SelectionItem: Sendable where Value: Sendable {}

// MARK: - SelectionRequirement
enum SelectionRequirement: Sendable, Hashable {
	case exactly(Int)
	case atLeast(Int)

	enum Quantifier: Sendable, Hashable {
		case exactly
		case atLeast
	}

	var quantifier: Quantifier {
		switch self {
		case .exactly: .exactly
		case .atLeast: .atLeast
		}
	}

	var count: Int {
		switch self {
		case let .exactly(count), let .atLeast(count):
			count
		}
	}
}

// MARK: - Selection
struct Selection<Value: Hashable, Content: View>: View {
	typealias Item = SelectionItem<Value>

	@Binding
	var selection: [Value]?
	@State
	var selectedValues: Set<Value>
	let values: OrderedSet<Value>
	let requirement: SelectionRequirement
	var showSelectAll: Bool = false
	let content: (Item) -> Content

	private var isFullySelected: Bool {
		selectedValues == Set(values)
	}

	init(
		_ selection: Binding<[Value]?>,
		from values: some Sequence<Value>,
		requiring requirement: SelectionRequirement,
		showSelectAll: Bool = false,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self._selection = selection
		self.selectedValues = selection.wrappedValue.map(Set.init) ?? []
		self.values = OrderedSet(values)
		self.requirement = requirement
		self.showSelectAll = showSelectAll
		self.content = content
	}

	init(
		_ selection: Binding<Value?>,
		from values: some Sequence<Value>,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self._selection = Binding<[Value]?>(
			get: {
				if let value = selection.wrappedValue {
					[value]
				} else {
					nil
				}
			},
			set: { newValue in
				selection.wrappedValue = newValue?.first
			}
		)
		self.selectedValues = selection.wrappedValue.map { [$0] } ?? []
		self.values = OrderedSet(values)
		self.requirement = .exactly(1)
		self.content = content
	}

	var body: some View {
		VStack(spacing: .medium2) {
			if showSelectAll, requirement != .exactly(1), !values.isEmpty {
				Button(isFullySelected ? "Deselect all" : "Select all") {
					if isFullySelected {
						selectedValues = []
					} else {
						selectedValues = Set(values)
					}
				}
				.buttonStyle(.blueText(textStyle: .secondaryHeader))
				.flushedRight
				.padding(.trailing, .small1)
			}

			ForEach(values, id: \.self) { value in
				let isDisabled: Bool = {
					guard !selectedValues.contains(value) else {
						return false
					}
					switch requirement {
					case let .exactly(count):
						if count == 1 {
							return false
						} else {
							return selectedValues.count >= count
						}
					case .atLeast:
						return false
					}
				}()
				content(
					Item(
						value: value,
						isSelected: selectedValues.contains(value),
						isDisabled: isDisabled,
						action: {
							if requirement == .exactly(1) {
								if !selectedValues.contains(value) {
									selectedValues.removeAll()
									selectedValues.insert(value)
								}
							} else {
								if selectedValues.contains(value) {
									selectedValues.remove(value)
								} else {
									selectedValues.insert(value)
								}
							}
						}
					)
				)
				.disabled(isDisabled)
			}
		}
		.onAppear {
			updateResult(with: selectedValues, in: values, requiring: requirement)
		}
		.onChange(of: selectedValues) { selectedValues in
			updateResult(with: selectedValues, in: values, requiring: requirement)
		}
		.onChange(of: selection) { selection in
			if let selection {
				selectedValues = Set(selection)
			} else {
				selectedValues = []
			}
		}
	}

	@MainActor
	private func updateResult(
		with chosenValues: Set<Value>,
		in values: some Collection<Value>,
		requiring requirement: SelectionRequirement
	) {
		if requirement.quantifier == .exactly {
			self.selectedValues = Set(values.filter(chosenValues.contains).prefix(requirement.count))
		}
		let rawValue = Array(values.filter(chosenValues.contains))
		if rawValue.count >= requirement.count {
			selection = rawValue
		} else {
			selection = nil
		}
	}
}

#if DEBUG
struct Selection_PreviewProvider: PreviewProvider {
	static var previews: some View {
		SingleSelection_Preview().previewDisplayName("Single - Exactly 1")

		MultiSelection_Preview(requirement: .exactly(0)).previewDisplayName("Multi - Exactly 0")
		MultiSelection_Preview(requirement: .exactly(1)).previewDisplayName("Multi - Exactly 1")
		MultiSelection_Preview(requirement: .exactly(2)).previewDisplayName("Multi - Exactly 2")

		MultiSelection_Preview(requirement: .atLeast(0)).previewDisplayName("Multi - At least 0")
		MultiSelection_Preview(requirement: .atLeast(1)).previewDisplayName("Multi - At least 1")
		MultiSelection_Preview(requirement: .atLeast(2)).previewDisplayName("Multi - At least 2")
	}
}

struct SingleSelection_Preview: View {
	@State
	var selection: Int? = nil

	var body: some View {
		List {
			Selection($selection, from: 1 ... 10) { item in
				HStack {
					Text(String(item.value))
					Spacer()
					Button(action: item.action) {
						Image(systemName: item.isSelected ? "circle.fill" : "circle")
					}
				}
			}
		}
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

struct MultiSelection_Preview: View {
	@State
	var selection: [Int]? = nil
	let requirement: SelectionRequirement

	var body: some View {
		List {
			Selection($selection, from: 1 ... 10, requiring: requirement) { item in
				HStack {
					Text(String(item.value))
					Spacer()
					Button(action: item.action) {
						if requirement == .exactly(1) {
							Image(systemName: item.isSelected ? "circle.fill" : "circle")
						} else {
							Image(systemName: item.isSelected ? "square.fill" : "square")
						}
					}
				}
			}
		}
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
