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
    }

    @IBOutlet weak var collectionView: UICollectionView!
}

// MARK: view
extension SavedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.dataSource = Store.shared
        self.collectionView.delegate = self
        self.collectionView.reloadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.reloadData()
    }
}

// MARK: actions
extension SavedViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.reader.rawValue {
            (segue.destination as! ReaderViewController).series = sender! as? Series
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
    }

    func editSeriesAction(_ sender: IndexPath) {
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
        let size = floor((collectionView.frame.width - 10 * 4) / 3) - 5

        return CGSize(width: size,
                      height: size)
    }
}

// MARK: collection view data source
extension Store: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        enum Tags: Int {
            case thumbnail = 1
            case title = 2
            case url = 3
        }
        
        var cell: UICollectionViewCell!
        if indexPath.row == Store.shared.count {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addCell", for: indexPath)
        } else {
            let series = self.series[indexPath.row]
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

            DispatchQueue.global(qos: .background).async {
                guard let url = series.thumbnail else { return }
                guard let data = ImageProxyCache.sharedProxy.cachedImageData(for: url) else { return }
                guard let image = UIImage(data: data) else { return }

                DispatchQueue.main.sync {
                    (cell.viewWithTag(Tags.thumbnail.rawValue) as? UIImageView)?.image = image
                }
            }

            (cell.viewWithTag(Tags.title.rawValue) as? UILabel)?.text = series.title
            (cell.viewWithTag(Tags.url.rawValue) as? UILabel)?.text = series.url.absoluteString
        }

        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 5
        return cell
    }
}
