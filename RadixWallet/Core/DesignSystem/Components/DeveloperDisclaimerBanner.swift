
extension View {
	@MainActor
	func showDeveloperDisclaimerBanner(_ store: Store<Bool, Never>) -> some View {
		VStack(spacing: 0) {
			WithViewStore(store, observe: { $0 }) { viewStore in
				if viewStore.state {
					DeveloperDisclaimerBanner()
				}
			}
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
