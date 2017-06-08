//
//  URLCacheDelegated.swift
//  Panelchan
//
//  Created by shdwprince on 5/26/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit
import Dispatch

class ImageResolver {
    static let shared = ImageResolver()
    static let CacheTimeout = 10.0

    func cachedImageData(for url: URL) -> Data? {
        return RNCachingURLProtocol.cachedData(for: url)
    }

    func waitForImageData(for url: URL, callback: @escaping ((UIImage?) -> Void)) {
        func sendRequest(cachePolicy: URLRequest.CachePolicy) -> Data? {
            return try? NSURLConnection.sendSynchronousRequest(URLRequest(url: url,
                                                                          cachePolicy: cachePolicy,
                                                                          timeoutInterval: 10.0),
                                                               returning: nil)
        }
        
        if let data = self.cachedImageData(for: url) {
            callback(UIImage(data: data))
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let end = CFAbsoluteTimeGetCurrent() + ImageResolver.CacheTimeout
                // check cache
                var data = sendRequest(cachePolicy: .returnCacheDataDontLoad)

                // check spoofed
                while true {
                    if let _data = self.cachedImageData(for: url) {
                        data = _data
                        break
                    }

                    if CFAbsoluteTimeGetCurrent() > end {
                        break
                    } else {
                        print("Slept in cache")
                        Thread.sleep(forTimeInterval: 0.3)
                    }
                }

                // load
                print("Falling back")
                data = sendRequest(cachePolicy: .returnCacheDataElseLoad)

                let result = data != nil ? UIImage(data: data!) : nil
                DispatchQueue.main.sync {
                    callback(result)
                }
            }
        }
    }
}
