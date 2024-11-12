import Foundation

extension CGRect {
	subscript(unitPoint: UnitPoint) -> CGPoint {
		.init(x: minX + unitPoint.x * width, y: minY + unitPoint.y * height)
	}

	var center: CGPoint {
		.init(x: midX, y: midY)
	}
}
