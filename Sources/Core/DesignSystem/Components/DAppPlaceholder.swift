import Prelude
import SwiftUI

// MARK: - DAppPlaceholder

public struct DAppPlaceholder: View {
	public init() { }
	
	public var body: some View {
		RoundedRectangle(cornerRadius: .small2)
			.fill(.app.gray4)
			.frame(.small)
	}
}

// MARK: - Previews

struct DAppPlaceholder_Previews: PreviewProvider {
	static var previews: some View {
		DAppPlaceholder()
	}
}
