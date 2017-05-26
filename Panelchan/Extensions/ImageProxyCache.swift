//
//  URLCacheDelegated.swift
//  Panelchan
//
//  Created by shdwprince on 5/26/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation

class ImageProxyCache: URLCache {
    static let sharedProxy = ImageProxyCache()

    fileprivate let baseUrl = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
    fileprivate let queue = OperationQueue()

    func cachedImageData(for url: String) -> Data? {
        return try? Data(contentsOf: self.url(for: url))
    }

    func waitForImageData(for url: String, callback: @escaping ((Data?) -> Void)) {
        if let data = self.cachedImageData(for: url) {
            callback(data)
        } else {
            self.queue.addOperation {
                let end = CFAbsoluteTimeGetCurrent() + 10.0
                while true {
                    if let data = self.cachedImageData(for: url) {
                        OperationQueue.main.addOperation {
                            callback(data)
                        }
                        break
                    }

                    if CFAbsoluteTimeGetCurrent() > end {
                        break
                    } else {
                        print("Slept in cache")
                        Thread.sleep(forTimeInterval: 0.3)
                    }
                }
            }
        }
    }

    func shouldCache(response cached: CachedURLResponse) -> Bool {
        if let res = cached.response as? HTTPURLResponse,
           let contentType = res.allHeaderFields["Content-Type"] as? String, contentType.contains("image") {
            return true
        } else {
            return false
        }
    }

    func cacheImageData(from cached: CachedURLResponse) {
        /*
        print("CACHING IMAGE")
        print(cached.response.url)
        print(cached.data.count)
        print("@@@@@@@@@@@")
         */
        if let url = cached.response.url?.absoluteString {
            try! cached.data.write(to: self.url(for: url))
        }
    }

    fileprivate func url(for string: String) -> URL {
        let length = Int(CC_MD5_DIGEST_LENGTH)

        let data = string.data(using: String.Encoding.utf8)!
        let hash = data.withUnsafeBytes { (bytes: UnsafePointer<Data>) -> [UInt8] in
            var hash: [UInt8] = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes, CC_LONG(data.count), &hash)
            return hash
        }

        let filename = (0..<length).map { String(format: "%02x", hash[$0]) }.joined()
        return URL(fileURLWithPath: self.baseUrl.appending("/").appending(filename))
    }
}

extension ImageProxyCache {
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        let cachedResponse = super.cachedResponse(for: request)

        if let cached = cachedResponse, self.shouldCache(response: cached) {
            self.cacheImageData(from: cached)
        }

        return cachedResponse
    }
    
    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        super.storeCachedResponse(cachedResponse, for: request)

        if self.shouldCache(response: cachedResponse) {
            self.cacheImageData(from: cachedResponse)
        }
    }

    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        super.storeCachedResponse(cachedResponse, for: dataTask)

        if self.shouldCache(response: cachedResponse) {
            self.cacheImageData(from: cachedResponse)
        }
    }
}
