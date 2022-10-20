import SwiftUI

import SwiftUI

// MARK: - BackButton
public struct CheckmarkView: View {
    public var isChecked: Bool
    
    public init(isChecked: Bool) {
        self.isChecked = isChecked
    }
}

public extension CheckmarkView {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isChecked ? Color.green : Color.gray)
            .frame(width: 20, height: 20)
    }
}

// MARK: - BackButton_Previews
struct CheckmarkView_Previews: PreviewProvider {
    static var previews: some View {
        CheckmarkView(isChecked: true)
    }
}
