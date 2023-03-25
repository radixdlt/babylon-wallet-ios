import FeaturePrelude

struct DappPermissionBox<Header: View, Content: View>: View {
	let header: Header
	let content: Content

	init(
		@ViewBuilder header: () -> Header = { EmptyView() },
		@ViewBuilder content: () -> Content
	) {
		self.header = header()
		self.content = content()
	}

	var body: some View {
		VStack(spacing: 0) {
			if !(header is EmptyView) {
				header
					.padding(.vertical, .medium1)
					.padding(.horizontal, .medium2)
					.frame(maxWidth: .infinity, alignment: .leading)
				Separator()
			}
			content
				.padding(.medium2)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
	}
}
