//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-08-10.
//

import Foundation

/// A client for querying if passcode and biometrics are set up.
///
/// Example usage in SwiftUI:
///
///     struct LocalAuthView: View {
///         @State var laConfig: LocalAuthenticationConfig?
///         var body: some View {
///
///             if let laConfig = laConfig {
///                 VStack {
///                     Text("\(String(describing: laConfig)) set up.")
///                     Button("Query again") {
///                         self.laConfig = nil
///                     }
///                 }
///             } else {
///                 Button("Ask for passcode/biometrics") {
///                     queryLAConfig()
///                 }
///             }
///         }
///
///         func queryLAConfig() {
///             Task {
///                 do {
///                     self.laConfig =  try await LocalAuthenticationClient.live().queryConfig() {
///                 } cath {
///                     print("User cancelled LA config query or failed: \(error)")
///                 }
///             }
///         }
///     }
public struct LocalAuthenticationClient {
	/// The return value (`LocalAuthenticationConfig`) might be `nil` if app goes to background or stuff like that.
	public typealias QueryConfig = @Sendable () async throws -> LocalAuthenticationConfig

	public var queryConfig: QueryConfig

	public init(queryConfig: @escaping QueryConfig) {
		self.queryConfig = queryConfig
	}
}
