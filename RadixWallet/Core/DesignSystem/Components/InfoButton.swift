import SwiftUI

struct InfoButton: View {
	let item: InfoLinkSheet.GlossaryItem
	let label: String?

	init(_ item: InfoLinkSheet.GlossaryItem, label: String? = nil) {
		self.item = item
		self.label = label
	}

	var body: some View {
		Button(action: showInfo) {
			if let label {
				Text(label)
			}
		}
		.buttonStyle(.info)
		.foregroundColor(label != nil ? .app.blue2 : .app.gray3)
	}

	private func showInfo() {
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		overlayWindowClient.showInfoLink(.init(glossaryItem: item))
	}
}
