import SwiftUI

// MARK: - NavigationBar
public struct NavigationBar<Content>: View where Content: View {
	let titleText: String?
	let leadingButton: Content?
	let trailingButton: Content?

	public init(
		titleText: String? = nil,
		leadingButton: (() -> Content)? = nil,
		trailingButton: (() -> Content)? = nil
	) {
		self.titleText = titleText
		self.leadingButton = leadingButton?()
		self.trailingButton = trailingButton?()
	}

	public var body: some View {
		HStack {
			if let leadingButton = leadingButton {
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

			if let trailingButton = trailingButton {
				trailingButton
			} else {
				placeholderSpacer
			}
		}
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
			leadingButton: { Button("Settings", action: {}) },
			trailingButton: { Button("Settings", action: {}) }
		)
	}
}
#endif // DEBUG
