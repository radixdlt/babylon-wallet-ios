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

// MARK: - Choose
public struct Choose<Value: Hashable, Content: View>: View {
	public struct Item {
		public let value: Value
		public var isChosen: Bool
		public var isDisabled: Bool
		public var action: () -> Void
	}

	let requirement: ChoiceRequirement
	let values: OrderedSet<Value>
	@State
	var chosenValues: Set<Value>
	@Binding
	var result: [Value]?
	let content: (Item) -> Content

	public init(
		_ requirement: ChoiceRequirement,
		from values: some Collection<Value>,
		through result: Binding<[Value]?>,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self.requirement = requirement
		self.values = OrderedSet(values)
		self.chosenValues = result.wrappedValue.map(Set.init) ?? []
		self._result = result
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
			updateResult(&result, with: chosenValues, from: values, under: requirement)
		}
		.onChange(of: chosenValues) { chosenValues in
			updateResult(&result, with: chosenValues, from: values, under: requirement)
		}
	}

	private func updateResult(
		_ result: inout [Value]?,
		with chosenValues: Set<Value>,
		from values: some Collection<Value>,
		under requirement: ChoiceRequirement
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
			Choose(requirement, from: Array(1 ... 10), through: $choices) { item in
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
					Button("Continue", action: {})
						.buttonStyle(.primaryRectangular)
						.disabled(choices == nil)
						.opacity(choices == nil ? 0.3 : 1)
				}
				.padding()
			}
			.background(Color.white)
		}
	}
}
#endif
