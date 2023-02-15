import Resources
import SwiftUI

public extension ButtonStyle where Self == RadixButtonStyle {
	static var radix: RadixButtonStyle { .init(textColor: .app.gray1, backgroundColor: .app.gray4) }
	static var destructive: RadixButtonStyle { .init(textColor: .white, backgroundColor: .app.red1) }
}

// MARK: - RadixButtonStyle
public struct RadixButtonStyle: ButtonStyle {
	let textColor: Color
	let backgroundColor: Color

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.foregroundColor(textColor)
			.frame(maxWidth: .infinity)
			.frame(height: .standardButtonHeight)
			.background(backgroundColor.clipShape(.radixButton))
	}
}

extension Shape where Self == RoundedRectangle {
	static var radixButton: Self {
		RoundedRectangle(cornerRadius: .small1, style: .continuous)
	}
}
