import Prelude

extension RawRepresentable where Self: CustomDumpRepresentable {
	public var customDumpValue: Any {
		rawValue
	}
}
