import Prelude

public extension RawRepresentable where Self: CustomDumpRepresentable {
	var customDumpValue: Any {
		rawValue
	}
}
