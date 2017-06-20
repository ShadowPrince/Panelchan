//
//  Reader.swift
//  Panelchan
//
//  Created by shdwprince on 5/27/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class ReaderViewController: UIViewController {
    enum Segues: String {
        case webViewError = "webViewError"
    }

    struct ScrollLock {
        let zoom: CGFloat
        let position: CGPoint
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var blurView: DynamicBlurView!
    var blurAnimationRunning = false

    @IBOutlet var tapNextRecognizer: UITapGestureRecognizer!
    @IBOutlet var tapBarRecognizer: UITapGestureRecognizer!

    @IBOutlet var barHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var barView: ILTranslucentView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!

    var webView = UIWebView()
    var series: Series?
    var chanController: ChanController?

    var scrollLock: ScrollLock?
}

// MARK: image view
extension ReaderViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewFitImage() {
        guard let imageSize = self.imageView.image?.size else { return }

        var source: CGFloat!
        var target: CGFloat!
        
        if imageSize.width > imageSize.height {
            source = imageSize.height
            target = self.scrollView.frame.height
        } else {
            source = imageSize.width
            target = self.scrollView.frame.width
        }

        self.scrollView.minimumZoomScale = target / source
        self.scrollView.zoomScale = target / source
    }

    func updatedImage() {
        self.scrollViewFitImage()

        if let lock = self.scrollLock {
            self.scrollView.setZoomScale(lock.zoom, animated: true)
            self.scrollView.setContentOffset(lock.position, animated: true)
        } else {
            self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
}

// MARK: view
extension ReaderViewController {
    override func viewDidLoad() {
        self.chanController = ChanController(webView: self.webView, series: self.series!)
        self.chanController?.delegate = self

        self.chanController?.setupWebView()
        self.controls(locked: true)

        self.titleLabel.text = self.series?.title
        self.domainLabel.text = self.series?.url.host

        self.tapBarRecognizer.numberOfTouchesRequired = Settings.shared.controlType == 1 ? 2 : 1
        self.tapNextRecognizer.numberOfTouchesRequired = Settings.shared.controlType == 1 ? 1 : 2

        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserManualViewController.showIfNeeded(at: self, of: .reader)
    }

    func controls(locked l: Bool) {
        self.prevButton.isEnabled = !l
        self.nextButton.isEnabled = !l
        self.tapNextRecognizer.isEnabled = !l

        self.blurView.blurRadius = l ? 100 : 0
        self.blurView.alpha = l ? 1 : 0

        /*
        if l {
            self.blurView.alpha = 1
        }

        self.blurView.animationQueue.queue(duration: 1, {
            self.blurView.blurRadius = l ? 100 : 0
        }, {
            self.blurView.alpha = l ? 1 : 0
        })
 */
    }
}

// MARK: actions
extension ReaderViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.webViewError.rawValue {
            (segue.destination as! WebViewErrorViewController).webView = self.webView
        }

        super.prepare(for: segue, sender: sender)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func previousAction(_ sender: Any) {
        self.chanController?.requestPrev()
        self.controls(locked: true)
    }

    @IBAction func tapNextAction(_ sender: Any) {
        self.nextAction(sender)
    }

    @IBAction func nextAction(_ sender: Any) {
        self.chanController?.requestNext()
        self.controls(locked: true)
    }
    
    @IBAction func tapToggleBarAction(_ sender: Any) {
        let isActive = !self.barHeightConstraint.isActive
        if isActive {
            self.barHeightConstraint.isActive = true
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.barView.alpha = isActive ? 1.0 : 0.0
        }) { _ in
            if !isActive {
                self.barHeightConstraint.isActive = false
            }
        }

        UIApplication.shared.isStatusBarHidden = !isActive
    }

    @IBAction func toggleLockAction(_ sender: UIButton) {
        if self.scrollLock == nil {
            self.scrollLock = ScrollLock(zoom: self.scrollView.zoomScale,
                                         position: self.scrollView.contentOffset)
            sender.setTitle("", for: .normal)
        } else {
            self.scrollLock = nil
            sender.setTitle("", for: .normal)
        }
    }
}

// MARK: chan controller
extension ReaderViewController: ChanControllerDelegate {
    func chanController(_ controller: ChanController, gotImage url: URL) {
        print("got image \(url)")
        ImageResolver.shared.waitForImageData(for: url) { (image) in
            if let image = image {
                self.imageView.image = image
                self.updatedImage()
            } else {
                self.present(UIAlertController(title: "Error", message: "Failed to load image", preferredStyle: .alert), animated: true, completion: nil)
            }

            self.controls(locked: false)
        }
    }

    func chanController(_ controller: ChanController, didFailWith error: ChanController.Errors) {
        self.controls(locked: false)
        self.performSegue(withIdentifier: Segues.webViewError.rawValue, sender: nil)
    }
}
