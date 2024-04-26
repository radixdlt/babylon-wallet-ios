import Foundation
import Sargon

extension BaseIdentifiedCollection {
	public var ids: [Element.ID] {
		map(\.id)
	}
}
