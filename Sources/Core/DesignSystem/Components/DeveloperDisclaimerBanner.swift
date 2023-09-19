import Resources
import SwiftUI

extension View {
	@ViewBuilder
	public func showDeveloperDisclaimerBanner(_ show: Bool) -> some View {
		VStack(spacing: 0) {
			if show {
				DeveloperDisclaimerBanner()
			}
			self
		}
	}
}

// MARK: - DeveloperDisclaimerBanner
public struct DeveloperDisclaimerBanner: View {
	public var body: some View {
		Text(L10n.Common.developerDisclaimerText)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.small3)
			.background(Color.app.orange2)
			.textStyle(.body2HighImportance)
	}

	public init() {}
}
