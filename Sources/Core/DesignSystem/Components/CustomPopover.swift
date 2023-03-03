#if canImport(UIKit)
import SwiftUI

// MARK: - CustomPopover
struct CustomPopover<Content: View> {
	@Binding var isPresented: Bool
	let onDismiss: (() -> Void)?
	@ViewBuilder let content: () -> Content

	class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
		let host: UIHostingController<Content>
		private let parent: CustomPopover

		init(
			parent: CustomPopover,
			content: Content
		) {
			self.parent = parent
			self.host = .init(rootView: content)
		}

		func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
			parent.isPresented = false
			if let onDismiss = parent.onDismiss {
				onDismiss()
			}
		}

		func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
			.none
		}
	}
}

// MARK: UIViewControllerRepresentable
extension CustomPopover: UIViewControllerRepresentable {
	typealias UIViewControllerType = UIViewController

	func makeUIViewController(context: Context) -> UIViewController {
		UIViewController()
	}

	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
		context.coordinator.host.rootView = self.content()

		guard isPresented, uiViewController.presentedViewController == nil else { return }
		let host = context.coordinator.host
		host.preferredContentSize = host.sizeThatFits(
			in: CGSize(
				width: CGFloat.greatestFiniteMagnitude,
				height: CGFloat.greatestFiniteMagnitude
			)
		)
		host.modalPresentationStyle = .popover
		host.popoverPresentationController?.delegate = context.coordinator
		host.popoverPresentationController?.sourceView = uiViewController.view
		host.popoverPresentationController?.sourceRect = uiViewController.view.bounds
		uiViewController.present(host, animated: true, completion: nil)
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self, content: self.content())
	}
}

// MARK: - CustomPopoverViewModifier
struct CustomPopoverViewModifier<PopoverContent>: ViewModifier where PopoverContent: View {
	@Binding var isPresented: Bool
	let onDismiss: (() -> Void)?
	let content: () -> PopoverContent

	func body(content: Content) -> some View {
		content.background(
			CustomPopover(
				isPresented: self.$isPresented,
				onDismiss: self.onDismiss,
				content: self.content
			)
		)
	}
}

// MARK: - ViewModifier
extension View {
	public func customPopover<Content>(
		isPresented: Binding<Bool>,
		onDismiss: (() -> Void)? = nil,
		content: @escaping () -> Content
	) -> some View where Content: View {
		modifier(
			CustomPopoverViewModifier(
				isPresented: isPresented,
				onDismiss: onDismiss,
				content: content
			)
		)
	}
}
#endif // UIKit
