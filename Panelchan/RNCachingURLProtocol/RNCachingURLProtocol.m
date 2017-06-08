//
//  RNCachingURLProtocol.m
//
//  Created by Robert Napier on 1/10/12.
//  Copyright (c) 2012 Rob Napier.
//
//  This code is licensed under the MIT License:
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "RNCachingURLProtocol.h"
#import "Reachability.h"
#import "NSString+Sha1.h"

static NSString *RNCachingURLHeader = @"X-RNCache";

@interface RNCachingURLProtocol ()
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property NSFileHandle *handle;
@end

@implementation RNCachingURLProtocol

- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest {
    return [RNCachingURLProtocol cachePathForURL:aRequest.URL];
}

+ (NSString *) cachePathForURL:(NSURL *) url {
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [[url absoluteString] sha1];
    
    return [cachesPath stringByAppendingPathComponent:fileName];
}

+ (NSData *) cachedDataFor:(NSURL *) url {
    return [NSData dataWithContentsOfFile:[[self cachePathForURL:url] stringByAppendingString:@"_finished"]];
}

+ (void)initialize {
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request valueForHTTPHeaderField:RNCachingURLHeader] == nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *connectionRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
    [[self request] mutableCopyWorkaround];
#else
    [[self request] mutableCopy];
#endif
    [connectionRequest setValue:@"" forHTTPHeaderField:RNCachingURLHeader];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest
                                                                delegate:self];
}

- (void)stopLoading {
    [[self connection] cancel];
}

// NSURLConnection delegates (generally we pass these on to our client)

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    // Thanks to Nick Dowell https://gist.github.com/1885821
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
        [request mutableCopyWorkaround];
#else
        [request mutableCopy];
#endif
        [redirectableRequest setValue:nil forHTTPHeaderField:RNCachingURLHeader];
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.handle) {
        [self.handle writeData:data];
    }

    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.handle) {
        [self.handle closeFile];
        [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForRequest:self.request] error:nil];
    }

    [[self client] URLProtocol:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *resp = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *) response : nil;
    if ([resp.allHeaderFields[@"Content-Type"] containsString:@"image"]) {
        NSString *path = [self cachePathForRequest:self.request];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        self.handle = [NSFileHandle fileHandleForWritingAtPath:[self cachePathForRequest:self.request]];
    }

    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.handle) {
        [self.handle closeFile];
        
        [[NSFileManager defaultManager] moveItemAtPath:[self cachePathForRequest:self.request]
                                                toPath:[[self cachePathForRequest:self.request] stringByAppendingString:@"_finished"]
                                                 error:nil];
    }

    [[self client] URLProtocolDidFinishLoading:self];
}

@end

#define WORKAROUND_MUTABLE_COPY_LEAK 1
#if WORKAROUND_MUTABLE_COPY_LEAK
// required to workaround http://openradar.appspot.com/11596316
@interface NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround;

@end

@implementation NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    if ([self HTTPBodyStream]) {
        [mutableURLRequest setHTTPBodyStream:[self HTTPBodyStream]];
    } else {
        [mutableURLRequest setHTTPBody:[self HTTPBody]];
    }
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];
    
    return mutableURLRequest;
}

@end
#endif
