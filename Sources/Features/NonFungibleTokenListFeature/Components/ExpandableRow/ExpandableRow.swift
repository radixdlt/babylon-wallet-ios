import SwiftUI

protocol ExpandableRow {
	var edge: Edge.Set { get }
	var value: CGFloat { get }
	var opositeValue: CGFloat { get }
}
