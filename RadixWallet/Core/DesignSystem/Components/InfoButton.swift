import SwiftUI

public struct InfoButton: View {
	public let item: InfoLinkSheet.GlossaryItem
	public let label: String?

	public init(_ item: InfoLinkSheet.GlossaryItem, label: String? = nil) {
		self.item = item
		self.label = label
	}

	public var body: some View {
		Button(action: showInfo) {
			if let label {
				Text(label)
			}
		}
		.buttonStyle(.info)
	}

	private func showInfo() {
		@Dependency(\.overlayWindowClient) var overlayWindowClient
		overlayWindowClient.showInfoLink(.init(glossaryItem: item))
	}
}
