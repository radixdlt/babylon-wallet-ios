import EngineToolkit

extension EntityType {
	public var isResourcePool: Bool {
		switch self {
		case .globalOneResourcePool, .globalTwoResourcePool, .globalMultiResourcePool:
			return true
		default:
			return false
		}
	}
}
