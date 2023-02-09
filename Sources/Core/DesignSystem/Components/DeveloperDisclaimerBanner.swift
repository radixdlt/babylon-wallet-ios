import Resources
import SwiftUI

public extension View {
	func showDeveloperDisclaimerBanner() -> some View {
		VStack(spacing: 0) {
			DeveloperDisclaimerBanner()
			self
		}
	}
}

// MARK: - DeveloperDisclaimerBanner
struct DeveloperDisclaimerBanner: View {
	var body: some View {
		Text(L10n.App.developmentOnlyInfo)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.small3)
			.background(Color.app.orange2)
			.textStyle(.body2HighImportance)
	}

	init() {}
}
