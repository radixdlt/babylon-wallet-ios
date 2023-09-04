import Resources
import SwiftUI

extension View {
	public func showDeveloperDisclaimerBanner(_ shouldShow: Bool) -> some View {
		VStack(spacing: 0) {
			if shouldShow {
				DeveloperDisclaimerBanner()
			}
			self
		}
	}
}

// MARK: - DeveloperDisclaimerBanner
private struct DeveloperDisclaimerBanner: View {
	var body: some View {
		Text(L10n.Common.developerDisclaimerText)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.small3)
			.background(Color.app.orange2)
			.textStyle(.body2HighImportance)
	}

	init() {}
}
