import Foundation

extension CGRect {
	public subscript(unitPoint: UnitPoint) -> CGPoint {
		.init(x: minX + unitPoint.x * width, y: minY + unitPoint.y * height)
	}

	public var center: CGPoint {
		.init(x: midX, y: midY)
	}
}
