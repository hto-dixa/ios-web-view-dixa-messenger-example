//
//  ViewController.swift
//  WidgetPlayground
//
//  Created by Hamidreza Tondkaranfar on 14/04/2025.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
    var webView: WKWebView!
    var webViewBottomConstraint: NSLayoutConstraint? // Store the bottom constraint
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Initialize WKWebViewConfiguration (optional, but good practice)
        let webConfiguration = WKWebViewConfiguration()
        // You can add custom configurations here if needed later
        
        // 2. Initialize WKWebView
        // Use frame: .zero initially, we'll use Auto Layout constraints
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self // Set the delegate
        webView.translatesAutoresizingMaskIntoConstraints = false // IMPORTANT for Auto Layout
        webView.scrollView.isScrollEnabled = false
        webView.isInspectable = true
        webView.scrollView.delegate = self
        
        // 3. Add the webView to the ViewController's view
        view.addSubview(webView)
        
        // 4. Set up Auto Layout constraints to make the webView fill the screen
        NSLayoutConstraint.activate([
            webView.topAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Store the bottom constraint
        webViewBottomConstraint = webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        webViewBottomConstraint?.isActive = true

        // 5. Load the URL
        let playgroundURL = URL(
            string: "http://localhost:8081"
        ) // <-- Replace if your URL is different
        if let url = playgroundURL {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            print("Error: Invalid URL")
            // Optionally display an error to the user
        }
        
        // Optional: Allow back/forward gestures
        webView.allowsBackForwardNavigationGestures = true

        // Add keyboard observers
        addKeyboardObservers()
    }
    
    deinit {
        // Remove observers when the view controller is deallocated
        removeKeyboardObservers()
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounds = webView.bounds
    }
    
    // Optional WKNavigationDelegate methods (examples)
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        print("Failed to load: \(error.localizedDescription)")
        // Handle loading errors (e.g., show an alert)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading")
        // Page has finished loading
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // Check if it's a server trust challenge
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let serverTrust = challenge.protectionSpace.serverTrust else {
                // Handle other authentication challenges or perform default handling
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // --- Insecurely trust the certificate (Use only for Debug/Development) ---
            // In a real app, you'd perform proper validation here,
            // possibly pinning the certificate or checking specific properties.
            #if DEBUG
                print("Allowing insecure certificate for development.")``
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            #else
                print("Rejecting insecure certificate in release build.")
                completionHandler(.cancelAuthenticationChallenge, nil) // Or .performDefaultHandling
            #endif
            // -------------------------------------------------------------------------

        }
    
    // MARK: - Keyboard Handling

    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        // Convert keyboard frame to view's coordinate system
        let keyboardHeight = view.convert(keyboardFrame, from: nil).height
        // Calculate the overlap with the safe area
        let bottomSafeAreaInset = view.safeAreaInsets.bottom
        let overlapHeight = keyboardHeight - bottomSafeAreaInset

        // Update constraint constant
        webViewBottomConstraint?.constant = -max(0, overlapHeight) // Adjust by the overlap

        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // Restore original constraint constant
        webViewBottomConstraint?.constant = 0

        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}

