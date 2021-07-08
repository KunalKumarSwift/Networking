//
//  SAImageFetcher.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation
import UIKit.UIImage

/// Error to be displayed when image downloading fails
public enum ImageFetcherError: Error {
    case imageURLNil
    case unableToFetchImage
}

public class SAImageFetcher {
    
    private let urlRequestBuilder = NetworkRequestBuilder()
    
    /// NSCache object used to cache image for key
    public static let cache = NSCache<NSString, UIImage>()
    
    public func fetchImage(url: URL?, completionHandler: @escaping (Result<UIImage, ImageFetcherError>) -> Void) {
        
        guard let url = url else {
            completionHandler(.failure(ImageFetcherError.imageURLNil))
            return
        }
        
        if let cachedImage = type(of: self).cache.object(forKey: url.absoluteString as NSString) {
            // we have image
            print("image found at cache -- URL == \(url.absoluteString)")
            completionHandler(.success(cachedImage))
            return
        }
        
        let urlRequest = urlRequestBuilder.buildURLRequest(withURL: url)
        
        SAContentFetcher.shared.requestContent(request: urlRequest) { (result) in
            
            switch result {
                
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completionHandler(.failure(ImageFetcherError.unableToFetchImage))
                    return
                }
                
                type(of: self).cache.setObject(image, forKey: url.absoluteString as NSString)
                completionHandler(.success(image))
                
            case .failure( _):
                completionHandler(.failure(ImageFetcherError.unableToFetchImage))
            }
        }
    }
}
