import ComposableArchitecture
import SwiftUI

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
				header.frame(maxWidth: .infinity, alignment: .leading)
				Separator()
			}
			content.frame(maxWidth: .infinity, alignment: .leading)
		}
		.background(.secondaryBackground)
		.cornerRadius(.medium3)
	}
}
