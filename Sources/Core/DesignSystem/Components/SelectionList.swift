import Resources
import SwiftUI

// MARK: - SelectionList
public struct SelectionList<Data: Sequence>: View where Data.Element: Hashable {
	public typealias Element = Data.Element

	let data: Data
	let title: (Element) -> String
	@Binding
	var selection: [Element]?
	let requirement: SelectionRequirement

	public init(
		_ data: Data,
		title: @escaping (Element) -> String,
		selection: Binding<[Element]?>,
		requiring requirement: SelectionRequirement
	) {
		self.data = data
		self.title = title
		self._selection = selection
		self.requirement = requirement
	}

	public var body: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				Selection($selection, from: data, requiring: requirement) { item in
					Button(action: item.action) {
						HStack(spacing: 0) {
							Text(title(item.value))
								.textStyle(.body1HighImportance)
								.foregroundColor(.app.gray1)
							Spacer()
							Image(
								asset: {
									if requirement == .exactly(1) {
										return item.isSelected
											? AssetResource.radioButtonDarkSelected
											: AssetResource.radioButtonDarkUnselected
									} else {
										return item.isSelected
											? AssetResource.checkmarkDarkSelected
											: AssetResource.checkmarkDarkUnselected
									}
								}()
							)
							.padding(.trailing, .small3)
							.opacity(item.isDisabled ? 0.3 : 1)
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
public struct SelectionList_PreviewProvider: PreviewProvider {
	public static var previews: some View {
		SelectionList_Preview(requirement: .exactly(0)).previewDisplayName("Exactly 0")
		SelectionList_Preview(requirement: .exactly(1)).previewDisplayName("Exactly 1")
		SelectionList_Preview(requirement: .exactly(2)).previewDisplayName("Exactly 2")

		SelectionList_Preview(requirement: .atLeast(0)).previewDisplayName("At least 0")
		SelectionList_Preview(requirement: .atLeast(1)).previewDisplayName("At least 1")
		SelectionList_Preview(requirement: .atLeast(2)).previewDisplayName("At least 2")
	}
}

public struct SelectionList_Preview: View {
	@State
	var selection: [Int]? = nil
	let requirement: SelectionRequirement

	public var body: some View {
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
			WithControlRequirements(selection, forAction: { print($0) }) { action in
				Button("Continue", action: action).buttonStyle(.primaryRectangular)
			}
		}
	}
}
#endif
