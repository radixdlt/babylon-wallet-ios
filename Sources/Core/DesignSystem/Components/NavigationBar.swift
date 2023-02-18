import SwiftUI

// MARK: - NavigationBar
public struct NavigationBar<LeadingItem: View, TrailingItem: View>: View {
	let titleText: String?
	let leadingItem: LeadingItem
	let trailingItem: TrailingItem

	public init(
		titleText: String? = nil,
		leadingItem: LeadingItem,
		trailingItem: TrailingItem
	) {
		self.titleText = titleText
		self.leadingItem = leadingItem
		self.trailingItem = trailingItem
	}
}

extension NavigationBar {
	public var body: some View {
		HStack {
			if let leadingButton = leadingItem {
				leadingButton
			} else {
				placeholderSpacer
			}

			Spacer()

			if let titleText = titleText {
				Text(titleText)
					.textStyle(.secondaryHeader)
			}

			Spacer()

			if let trailingButton = trailingItem {
				trailingButton
			} else {
				placeholderSpacer
			}
		}
		.frame(height: .navigationBarHeight)
	}
}

extension NavigationBar {
	public init(titleText: String? = nil, trailingItem: TrailingItem) where LeadingItem == EmptyView {
		self.init(
			titleText: titleText,
			leadingItem: EmptyView(),
			trailingItem: trailingItem
		)
	}

	public init(titleText: String? = nil, leadingItem: LeadingItem) where TrailingItem == EmptyView {
		self.init(
			titleText: titleText,
			leadingItem: leadingItem,
			trailingItem: EmptyView()
		)
	}

	public init(titleText: String) where LeadingItem == EmptyView, TrailingItem == EmptyView {
		self.init(
			titleText: titleText,
			leadingItem: EmptyView(),
			trailingItem: EmptyView()
		)
	}
}

// MARK: - Private Computed Properties
extension NavigationBar {
	private var placeholderSpacer: some View {
		Rectangle()
			.fill(.clear)
			.frame(.small)
	}
}

// extension View {
//	public func withNavigationBar(showDragHandle: Bool = false) -> some View {
//		VStack(spacing: 0) {
//
//			self
//		}
//	}
// }

#if DEBUG

// MARK: - NavigationBar_Previews
struct NavigationBar_Previews: PreviewProvider {
	static var previews: some View {
		NavigationBar(
			titleText: "A title",
			leadingItem: Button("Settings", action: {}),
			trailingItem: Button("Settings", action: {})
		)
	}
}
#endif // DEBUG
