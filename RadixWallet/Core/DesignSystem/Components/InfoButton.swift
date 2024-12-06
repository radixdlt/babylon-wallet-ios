import SwiftUI

struct InfoButton: View {
	let item: InfoLinkSheet.GlossaryItem
	let label: String?
	let showIcon: Bool

	init(_ item: InfoLinkSheet.GlossaryItem, label: String? = nil, showIcon: Bool = true) {
		self.item = item
		self.label = label
		self.showIcon = showIcon
	}

	var body: some View {
		Button(action: showInfo) {
			Text(label)
		}
		.buttonStyle(.info(showIcon: showIcon))
		.foregroundColor(label != nil ? .app.blue2 : .app.gray3)
	}

	private func showInfo() {
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		overlayWindowClient.showInfoLink(.init(glossaryItem: item))
	}
}
