import SwiftUI

// MARK: - NavigationBar
public struct NavigationBar<LeadingItem: View, TrailingItem: View>: View {
	let titleText: String?
	let leadingItem: LeadingItem?
	let trailingItem: TrailingItem?

	private init(
		titleText: String? = nil,
		leadingItem: (() -> LeadingItem)? = nil,
		trailingItem: (() -> TrailingItem)? = nil
	) {
		self.titleText = titleText
		self.leadingItem = leadingItem?()
		self.trailingItem = trailingItem?()
	}
}

public extension NavigationBar {
	var body: some View {
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
	}
}

public extension NavigationBar {
	init(
		titleText: String? = nil,
		leadingItem: LeadingItem,
		trailingItem: TrailingItem
	) {
		self.init(
			titleText: titleText,
			leadingItem: { leadingItem },
			trailingItem: { trailingItem }
		)
	}
}

public extension NavigationBar where LeadingItem == EmptyView {
	init(
		titleText: String? = nil,
		trailingItem: TrailingItem
	) {
		self.init(
			titleText: titleText,
			leadingItem: nil,
			trailingItem: { trailingItem }
		)
	}
}

public extension NavigationBar where TrailingItem == EmptyView {
	init(
		titleText: String? = nil,
		leadingItem: LeadingItem
	) {
		self.init(
			titleText: titleText,
			leadingItem: { leadingItem },
			trailingItem: nil
		)
	}
}

public extension NavigationBar where LeadingItem == EmptyView, TrailingItem == EmptyView {
	init(
		titleText: String? = nil
	) {
		self.init(
			titleText: titleText,
			leadingItem: nil,
			trailingItem: nil
		)
	}
}

// MARK: - Private Computed Properties
private extension NavigationBar {
	var placeholderSpacer: some View {
		Spacer()
			.frame(.small)
	}
}

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
