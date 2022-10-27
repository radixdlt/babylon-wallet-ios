import DesignSystem
import SwiftUI

// MARK: - TokenView
public struct TokenView: View {
	let code: String
}

public extension TokenView {
	var body: some View {
		ZStack {
			Circle()
				.strokeBorder(.orange, lineWidth: 1)
				.background(Circle().foregroundColor(Color.App.random))
			Text(code)
				.textCase(.uppercase)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.body2HighImportance)
		}
		.frame(width: 30, height: 30)
	}
}

// MARK: - TokenView_Previews
struct TokenView_Previews: PreviewProvider {
	static var previews: some View {
		TokenView(code: "XRD")
	}
}
