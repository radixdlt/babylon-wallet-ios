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
			Group {
				Text(heading)
					.sectionHeading
				Text(item)
					.infoItem
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

extension InfoPair {
	public init<Item: CustomStringConvertible>(heading: String, item: Item) {
		self.init(heading: heading, item: String(describing: item))
	}
}
