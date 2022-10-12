import DesignSystem
import SwiftUI

// MARK: - PermissionsView
struct PermissionsView: View {
	let permissions: [Permission]

	var body: some View {
		VStack(alignment: .leading) {
			ForEach(permissions) { permission in
				HStack(alignment: .top) {
					Text("•")
					Text(permission.description)
				}
				.foregroundColor(.app.gray1)
				.textStyle(.body1Regular)

				if let details = permission.details {
					Spacer()
						.frame(height: 10)

					HStack {
						Spacer()
							.frame(width: 50)

						PermissionDetails(details: details)

						Spacer()
							.frame(width: 10)
					}
				}
				Spacer()
					.frame(height: 30)
			}
		}
	}
}

// MARK: - PermissionDetails
struct PermissionDetails: View {
	let details: [String]

	var body: some View {
		VStack(alignment: .leading) {
			ForEach(details, id: \.self) { x in
				HStack(alignment: .top) {
					Text("•")
					Text(x)
				}
				.foregroundColor(.app.gray1)
				.textStyle(.body1Regular)
			}
		}
	}
}

// MARK: - PermissionsView_Previews
struct PermissionsView_Previews: PreviewProvider {
	static var previews: some View {
		PermissionsView(
			permissions: [.placeholder1, .placeholder2, .placeholder3]
		)
	}
}
