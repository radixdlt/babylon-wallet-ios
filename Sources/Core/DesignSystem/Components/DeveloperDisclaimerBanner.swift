import Resources
import SwiftUI

extension View {
	@ViewBuilder
	public func showDeveloperDisclaimerBanner(showIsUsingTestnetBanner: Bool) -> some View {
		if showIsUsingTestnetBanner {
			VStack(spacing: 0) {
				DeveloperDisclaimerBanner()
				self
			}
		} else {
			self
		}
	}
}

// MARK: - DeveloperDisclaimerBanner
struct DeveloperDisclaimerBanner: View {
	var body: some View {
		Text(L10n.Common.developerDisclaimerText)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.small3)
			.background(Color.app.orange2)
			.textStyle(.body2HighImportance)
	}

	init() {}
}
