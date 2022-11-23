import Foundation
import SwiftUI

// MARK: - NavigationBar
public struct NavigationBar: View {
	let action: () -> Void
	let style: Style
	let title: String

	public init(_ title: String, style: Style, action: @escaping () -> Void) {
		self.style = style
		self.action = action
		self.title = title
	}
}

/*
 #if DEBUG

 // MARK: - NavigationBar_Preview
 struct NavigationBar_Preview: PreviewProvider {
 	static var previews: some View {
 		NavigationBar(
 			"A title",
 			style: .close,
 			action: {}
 		)
 	}
 }
 #endif // DEBUG
 */

public extension NavigationBar {
	enum Style {
		case close, back
	}

	var body: some View {
		HStack {
			switch style {
			case .back:
				BackButton(action: action)
			case .close:
				CloseButton(action: action)
			}
			Spacer()
			Text(title)

			Spacer()
		}
	}
}

// MARK: - Header
public struct Header<Content: View>: View {
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
private extension Header {
	var placeholderSpacer: some View {
		Spacer()
			.frame(.small)
	}
}

#if DEBUG

// MARK: - Header_Previews
struct Header_Previews: PreviewProvider {
	static var previews: some View {
		Header(
			titleText: "A title",
			leadingButton: { Button("Settings", action: {}) },
			trailingButton: { Button("Settings", action: {}) }
		)
	}
}
#endif // DEBUG
