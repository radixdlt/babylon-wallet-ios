import UIKit

// MARK: - BannerViewController
public final class BannerViewController: UIViewController {
	private let banner: BannerView
	private let completed: () -> Void

	override public var preferredStatusBarStyle: UIStatusBarStyle {
		view.window?.windowScene?.statusBarManager?.statusBarStyle ?? .lightContent
	}

	public init(
		text: String,
		completed: @escaping () -> Void
	) {
		self.banner = BannerView(text: text)
		self.completed = completed
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public func viewDidLoad() {
		super.viewDidLoad()
		setInitialState()
	}

	override public func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		showBannerView()
	}
}

// MARK: - Private Methods
extension BannerViewController {
	private func setInitialState() {
		banner.alpha = 0
		banner.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(banner)
		NSLayoutConstraint.activate([
			banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			banner.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
		])
	}

	private func showBannerView() {
		UIView.animate(
			withDuration: Constants.animationDuration,
			animations: { [weak self] in
				self?.banner.alpha = 1
			}, completion: { [weak self] _ in
				self?.hideBannerView()
			}
		)
	}

	private func hideBannerView() {
		UIView.animate(
			withDuration: Constants.animationDuration,
			delay: Constants.presentationDuration,
			animations: { [weak self] in
				self?.banner.alpha = 0
			}, completion: { [weak self] _ in
				self?.completed()
			}
		)
	}
}

// MARK: BannerViewController.Constants
extension BannerViewController {
	private enum Constants {
		static let animationDuration: TimeInterval = 0.15
		static let presentationDuration: TimeInterval = 2
	}
}
