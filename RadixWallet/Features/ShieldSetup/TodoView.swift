import SwiftUI

struct TodoView: View {
	let feature: String

	var body: some View {
		VStack {
			Spacer()
			Text("TODO: Implement \(feature)")
				.textStyle(.sheetTitle)
				.multilineTextAlignment(.center)
			Spacer()
		}
		.padding(.horizontal, .medium1)
	}
}
