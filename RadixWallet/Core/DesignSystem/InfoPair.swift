// MARK: - VPair
public struct VPair: View {
	let heading: String
	let item: String

	public init(heading: String, item: String) {
		self.heading = heading
		self.item = item
	}
}

extension VPair {
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

extension VPair {
	public init(heading: String, item: some CustomStringConvertible) {
		self.init(heading: heading, item: String(describing: item))
	}
}

// MARK: - HPair
public struct HPair: View {
	let label: String
	let item: String

	public init(label: String, item: String) {
		self.label = label
		self.item = item
	}
}

extension HPair {
	public var body: some View {
		HStack(alignment: .center, spacing: .small2) {
			Group {
				Text(label)
					.textStyle(.body2Header)

				Text(item)
					.textStyle(.monospace)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
	}
}

extension HPair {
	public init(label: String, item: some CustomStringConvertible) {
		self.init(label: label, item: String(describing: item))
	}
}
