import SwiftUI

// MARK: - ScrollBarItem
protocol ScrollBarItem: Identifiable {
	var caption: String { get }
}

// MARK: - HScrollBar
struct HScrollBar<Item: ScrollBarItem>: View {
	let items: IdentifiedArrayOf<Item>
	@Binding var selection: Item.ID

	var body: some View {
		ScrollViewReader { proxy in
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: .zero) {
					ForEach(items) { item in
						let isSelected = item.id == selection
						Button {
							selection = item.id
						} label: {
							Text(item.caption.localizedUppercase)
								.foregroundStyle(isSelected ? .primaryText : .secondaryText)
						}
						.padding(.horizontal, .medium3)
						.padding(.vertical, .small2)
						.measurePosition(item.id, coordSpace: HScrollBar.coordSpace)
						.padding(.horizontal, .small3)
						.animation(.default, value: isSelected)
					}
				}
				.coordinateSpace(name: HScrollBar.coordSpace)
				.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
					if let rect = positions[selection] {
						Capsule()
							.fill(.tertiaryBackground)
							.frame(width: rect.width, height: rect.height)
							.position(x: rect.midX, y: rect.midY)
							.animation(.default, value: rect)
					}
				}
				.padding(.horizontal, .medium3)
			}
			.scrollIndicators(.never)
			.onChange(of: selection) { value in
				withAnimation {
					proxy.scrollTo(value, anchor: .center)
				}
			}
		}
	}

	private static var coordSpace: String { "HScrollBar.HStack" }
}
