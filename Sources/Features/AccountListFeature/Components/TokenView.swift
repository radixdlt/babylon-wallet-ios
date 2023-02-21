import FeaturePrelude

// MARK: - TokenView
public struct TokenView: View {
	let code: String
}

extension TokenView {
	public var body: some View {
		ZStack {
			Circle()
				.strokeBorder(.orange, lineWidth: 1)
				.background(Circle().fill(Color.App.random))
			Text(code)
				.textCase(.uppercase)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.body2HighImportance)
		}
		.frame(width: 30, height: 30)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct TokenView_Previews: PreviewProvider {
	static var previews: some View {
		TokenView(code: "XRD")
	}
}
#endif
