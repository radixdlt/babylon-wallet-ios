import NonEmpty
import OrderedCollections
import SwiftUI

// MARK: - SelectionItem
public struct SelectionItem<Value> {
	public let value: Value
	public var isSelected: Bool
	public var isDisabled: Bool
	public var action: () -> Void
}

// MARK: - SelectionRequirement
public enum SelectionRequirement: Hashable {
	case exactly(Int)
	case atLeast(Int)

	public enum Quantifier: Hashable {
		case exactly
		case atLeast
	}

	public var quantifier: Quantifier {
		switch self {
		case .exactly: return .exactly
		case .atLeast: return .atLeast
		}
	}

	public var count: Int {
		switch self {
		case let .exactly(count), let .atLeast(count):
			return count
		}
	}
}

// MARK: - Selection
public struct Selection<Value: Hashable, Content: View>: View {
	public typealias Item = SelectionItem<Value>

	@Binding
	var selection: [Value]?
	@State
	var selectedValues: Set<Value>
	let values: OrderedSet<Value>
	let requirement: SelectionRequirement
	let content: (Item) -> Content

	public init(
		_ selection: Binding<[Value]?>,
		from values: some Sequence<Value>,
		requiring requirement: SelectionRequirement,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self._selection = selection
		self.selectedValues = selection.wrappedValue.map(Set.init) ?? []
		self.values = OrderedSet(values)
		self.requirement = requirement
		self.content = content
	}

	public init(
		_ selection: Binding<Value?>,
		from values: some Sequence<Value>,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self._selection = Binding<[Value]?>(
			get: {
				if let value = selection.wrappedValue {
					return [value]
				} else {
					return nil
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

	public var body: some View {
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
public struct Selection_PreviewProvider: PreviewProvider {
	public static var previews: some View {
		SingleSelection_Preview().previewDisplayName("Single - Exactly 1")

		MultiSelection_Preview(requirement: .exactly(0)).previewDisplayName("Multi - Exactly 0")
		MultiSelection_Preview(requirement: .exactly(1)).previewDisplayName("Multi - Exactly 1")
		MultiSelection_Preview(requirement: .exactly(2)).previewDisplayName("Multi - Exactly 2")

		MultiSelection_Preview(requirement: .atLeast(0)).previewDisplayName("Multi - At least 0")
		MultiSelection_Preview(requirement: .atLeast(1)).previewDisplayName("Multi - At least 1")
		MultiSelection_Preview(requirement: .atLeast(2)).previewDisplayName("Multi - At least 2")
	}
}

public struct SingleSelection_Preview: View {
	@State
	var selection: Int? = nil

	public var body: some View {
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
			WithControlRequirements(selection, forAction: { print($0) }) { action in
				Button("Continue", action: action).buttonStyle(.primaryRectangular)
			}
		}
	}
}

public struct MultiSelection_Preview: View {
	@State
	var selection: [Int]? = nil
	let requirement: SelectionRequirement

	public var body: some View {
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
			WithControlRequirements(selection, forAction: { print($0) }) { action in
				Button("Continue", action: action).buttonStyle(.primaryRectangular)
			}
		}
	}
}
#endif
