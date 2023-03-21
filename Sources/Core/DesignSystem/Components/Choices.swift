import NonEmpty
import OrderedCollections
import SwiftUI

// MARK: - ChoiceRequirement
public enum ChoiceRequirement: Hashable {
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
		case
			let .exactly(count),
			let .atLeast(count):
			return count
		}
	}
}

// MARK: - Choices
public struct Choices<Value: Hashable, Content: View>: View {
	public struct Item {
		public let value: Value
		public var isChosen: Bool
		public var isDisabled: Bool
		public var action: () -> Void
	}

	@Binding
	var result: [Value]?
	@State
	var chosenValues: Set<Value>
	let values: OrderedSet<Value>
	let requirement: ChoiceRequirement
	let content: (Item) -> Content

	public init(
		_ choices: Binding<[Value]?>,
		in values: some Sequence<Value>,
		requiring requirement: ChoiceRequirement,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self._result = choices
		self.chosenValues = choices.wrappedValue.map(Set.init) ?? []
		self.values = OrderedSet(values)
		self.requirement = requirement
		self.content = content
	}

	public var body: some View {
		ForEach(values, id: \.self) { value in
			content(
				Item(
					value: value,
					isChosen: chosenValues.contains(value),
					isDisabled: {
						guard !chosenValues.contains(value) else {
							return false
						}
						switch requirement {
						case let .exactly(count):
							if count == 1 {
								return false
							} else {
								return chosenValues.count >= count
							}
						case .atLeast:
							return false
						}
					}(),
					action: {
						if requirement == .exactly(1) {
							if !chosenValues.contains(value) {
								chosenValues.removeAll()
								chosenValues.insert(value)
							}
						} else {
							if chosenValues.contains(value) {
								chosenValues.remove(value)
							} else {
								chosenValues.insert(value)
							}
						}
					}
				)
			)
		}
		.onAppear {
			updateResult(with: chosenValues, in: values, requiring: requirement)
		}
		.onChange(of: chosenValues) { chosenValues in
			updateResult(with: chosenValues, in: values, requiring: requirement)
		}
	}

	private func updateResult(
		with chosenValues: Set<Value>,
		in values: some Collection<Value>,
		requiring requirement: ChoiceRequirement
	) {
		if requirement.quantifier == .exactly {
			self.chosenValues = Set(values.filter(chosenValues.contains).prefix(requirement.count))
		}
		let rawValue = Array(values.filter(chosenValues.contains))
		if rawValue.count >= requirement.count {
			result = rawValue
		} else {
			result = nil
		}
	}
}

#if DEBUG
public struct Choose_PreviewProvider: PreviewProvider {
	public static var previews: some View {
		Choose_Preview(requirement: .exactly(0)).previewDisplayName("Exactly 0")
		Choose_Preview(requirement: .exactly(1)).previewDisplayName("Exactly 1")
		Choose_Preview(requirement: .exactly(2)).previewDisplayName("Exactly 2")

		Choose_Preview(requirement: .atLeast(0)).previewDisplayName("At least 0")
		Choose_Preview(requirement: .atLeast(1)).previewDisplayName("At least 1")
		Choose_Preview(requirement: .atLeast(2)).previewDisplayName("At least 2")
	}
}

public struct Choose_Preview: View {
	@State
	var choices: [Int]? = nil
	let requirement: ChoiceRequirement

	public var body: some View {
		List {
			Choices($choices, in: 1 ... 10, requiring: requirement) { item in
				HStack {
					Text(String(item.value))
					Spacer()
					Button(action: item.action) {
						if requirement == .exactly(1) {
							Image(systemName: item.isChosen ? "circle.fill" : "circle")
						} else {
							Image(systemName: item.isChosen ? "square.fill" : "square")
						}
					}
				}
				.disabled(item.isDisabled)
			}
		}
		.safeAreaInset(edge: .bottom, spacing: 0) {
			VStack(spacing: 0) {
				Divider()
				VStack {
					if let choices {
						Text("Result: \(String(describing: choices))")
					} else {
						Text("Result: nil")
					}
					WithControlRequirements(choices, forAction: { print($0) }) { action in
						Button("Continue", action: action).buttonStyle(.primaryRectangular)
					}
				}
				.padding()
			}
			.background(Color.white)
		}
	}
}
#endif
