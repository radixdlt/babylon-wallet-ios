import FeaturePrelude

// This doesn't actually seem to be used
protocol ExpandableRow {
	var edge: Edge.Set { get }
	var value: CGFloat { get }
	var oppositeValue: CGFloat { get }
}
