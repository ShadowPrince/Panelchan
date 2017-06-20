//
//  SavedViewController.swift
//  Panelchan
//
//  Created by shdwprince on 5/23/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SavedViewController: UIViewController {
    enum Segues: String {
        case saveGuide = "saveGuide"
        case reader = "reader"
        case settings = "settings"
    }

    @IBOutlet weak var collectionView: UICollectionView!
}

// MARK: view
extension SavedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserManualViewController.showIfNeeded(at: self, of: .saved)
    }
}

// MARK: actions
extension SavedViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.reader.rawValue {
            (segue.destination as! ReaderViewController).series = sender! as? Series
        }

        if segue.identifier == Segues.saveGuide.rawValue {
            let controller = segue.destination as! SaveGuideViewController
            controller.series = sender as? Series
        }

        if segue.identifier == Segues.settings.rawValue {
            if let cell = self.collectionView.cellForItem(at: IndexPath(row: Store.shared.count, section: 0)) {
                segue.destination.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.origin.x + cell.frame.size.width / 2,
                                                                                     y: cell.frame.origin.y + cell.frame.size.height * 0.75,
                                                                                     width: 1,
                                                                                     height: 1)
            }
        }

        super.prepare(for: segue, sender: sender)
    }

    @IBAction func seriesLongAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began,
           let indexPath = self.collectionView(indexAt: sender.location(in: self.collectionView)),
           indexPath.row != Store.shared.count
        {
            let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            menu.addAction(UIAlertAction(title: "Edit", style: .default, handler: { (_) in
                self.editSeriesAction(indexPath)
            }))

            menu.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                self.deleteSeriesAction(indexPath)
            }))

            menu.popoverPresentationController?.sourceView = self.collectionView.cellForItem(at: indexPath)
            self.present(menu, animated: true, completion: nil)
        }
    }

    func deleteSeriesAction(_ sender: IndexPath) {
        Store.shared.remove(at: sender.row)
        self.collectionView.deleteItems(at: [sender])
        Store.shared.store()
    }

    func editSeriesAction(_ sender: IndexPath) {
        let series = Store.shared.series[sender.row]
        self.performSegue(withIdentifier: Segues.saveGuide.rawValue, sender: series)
    }
    
    @IBAction func saveGuideAction(_ sender: Any) {
        self.performSegue(withIdentifier: Segues.saveGuide.rawValue, sender: nil)
    }

    @IBAction func readAction(_ sender: Series) {
        self.performSegue(withIdentifier: Segues.reader.rawValue, sender: sender)
    }
}

// MARK: collection view
extension SavedViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(indexAt p: CGPoint) -> IndexPath? {
        return self.collectionView.indexPathForItem(at: p)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != Store.shared.count {
            self.performChainAction(#selector(SavedViewController.readAction(_:)), sender: Store.shared.series[indexPath.row])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = floor((collectionView.frame.width - 30 * 4) / 3) - 5

        return CGSize(width: size,
                      height: size)
    }
}

// MARK: collection view data source
extension SavedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Store.shared.count + 1
    }

    func prepareAdd(cell: UICollectionViewCell, for indexPath: IndexPath) {
        enum Tags: Int {
            case add = 1
            case settings = 2
        }

        cell.viewWithTag(Tags.add.rawValue)?.layer.cornerRadius = 8
        cell.viewWithTag(Tags.settings.rawValue)?.layer.cornerRadius = 8

        cell._intrl_setupSmallShadow()
    }

    func prepareSeries(cell: UICollectionViewCell, for indexPath: IndexPath) {
        enum Tags: Int {
            case thumbnail = 1
            case title = 2
            case url = 3
            case bar = 4
        }

        let series = Store.shared.series[indexPath.row]
        let barView = cell.viewWithTag(Tags.bar.rawValue)

        barView?.layer.masksToBounds = true
        barView?.layer.cornerRadius = 8

        cell._simple_nil(tag: Tags.thumbnail.rawValue)
        cell._simple_register(for: indexPath)

        ImageResolver.shared.waitForImageData(for: series.thumbnail, callback: { (image) in
            if cell._simple_check(for: indexPath) {
                cell._simple_set(image, tag: Tags.thumbnail.rawValue)
            }
        })

        cell._simple_set(series.title, tag: Tags.title.rawValue)
        cell._simple_set(series.url.absoluteString, tag: Tags.url.rawValue)

        cell._intrl_setupSmallShadow()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!

        if indexPath.row == Store.shared.count {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCell", for: indexPath)
            self.prepareAdd(cell: cell, for: indexPath)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            self.prepareSeries(cell: cell, for: indexPath)
        }

        return cell
    }
}

// MARK: helpers
extension UIView {
    func _intrl_setupShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.masksToBounds = false
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    func _intrl_setupMediumShadow() {
        self._intrl_setupShadow()
        self.layer.shadowRadius = 48
        self.layer.shadowOpacity = 0.4
    }

    func _intrl_setupSmallShadow() {
        self._intrl_setupShadow()
        self.layer.shadowRadius = 14
        self.layer.shadowOpacity = 0.5
    }
}
