import Foundation
import Sargon

public typealias CAP26Path = Cap26Path

extension Cap26Path {
	public var asGeneral: DerivationPath {
		.cap26(value: self)
	}
}
