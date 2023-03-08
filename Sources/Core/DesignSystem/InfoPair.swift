import SwiftUI

// MARK: - InfoPair
public struct InfoPair: View {
	let heading: String
	let item: String

	public init(heading: String, item: String) {
		self.heading = heading
		self.item = item
	}
}

extension InfoPair {
	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(heading)
				.sectionHeading
			Text(item)
				.infoItem
		}
	}
}

extension InfoPair {
	public init<Item: CustomStringConvertible>(heading: String, item: Item) {
		self.init(heading: heading, item: String(describing: item))
	}
}
