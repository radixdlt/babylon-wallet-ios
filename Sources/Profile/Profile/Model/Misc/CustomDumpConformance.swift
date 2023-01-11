import CustomDump
import Foundation

public extension RawRepresentable where Self: CustomDumpRepresentable {
	var customDumpValue: Any {
		rawValue
	}
}
