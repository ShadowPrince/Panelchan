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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!

    var webView = UIWebView()
    var series: Series?
    var chanController: ChanController?
}

// MARK: image view
extension ReaderViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewFitImage() {
        var source: CGFloat!
        var target: CGFloat!
        
        let imageSize = self.imageView.image!.size
        if imageSize.width > imageSize.height {
            source = imageSize.height
            target = self.scrollView.frame.height
        } else {
            source = imageSize.width
            target = self.scrollView.frame.width
        }
        
        self.scrollView.zoomScale = target / source
    }

    func updatedImage() {
        self.scrollViewFitImage()
    }
}

// MARK: view
extension ReaderViewController {
    override func viewDidLoad() {
        self.chanController = ChanController(webView: self.webView, series: self.series!)
        self.chanController?.delegate = self

        self.chanController?.setupWebView()

        super.viewDidLoad()
    }

    override func viewWillLayoutSubviews() {
        self.scrollViewFitImage()
        super.viewWillLayoutSubviews()
    }

    func controls(locked l: Bool) {
        self.prevButton.isEnabled = !l
        self.nextButton.isEnabled = !l
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
    
    @IBAction func nextAction(_ sender: Any) {
        self.chanController?.requestNext()
        self.controls(locked: true)
    }
    
    @IBAction func previousAction(_ sender: Any) {
        self.chanController?.requestPrev()
        self.controls(locked: true)
    }
}

// MARK: chan controller
extension ReaderViewController: ChanControllerDelegate {
    func chanController(_ controller: ChanController, gotImage url: URL) {
        print("got image \(url)")
        ImageProxyCache.sharedProxy.waitForImageData(for: url) { (data) in
            if let data = data {
                self.imageView.image = UIImage(data: data)
                self.updatedImage()
            } else {
                print("Falling back to direct load")
                do {
                    self.imageView.image = UIImage(data: try Data(contentsOf: url))
                    self.updatedImage()
                } catch (let e) {
                    print("Failed to load: \(e)")
                }
            }

            self.controls(locked: false)
        }
    }

    func chanController(_ controller: ChanController, didFailWith error: Error) {
        self.controls(locked: false)
        self.performSegue(withIdentifier: Segues.webViewError.rawValue, sender: nil)
    }
}
