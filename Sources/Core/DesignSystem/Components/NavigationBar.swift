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
