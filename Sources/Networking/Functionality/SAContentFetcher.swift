//
//  SContentFetcher.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation

public typealias completionHandler = (Result<Data, SARequestError>) -> Void

public protocol ContentFetcherProtocol {
    func requestContent(request: URLRequest?, completionHandler: @escaping completionHandler)
}

public class SAContentFetcher: NSObject, ContentFetcherProtocol {
    
    // MARK: Public methods
    
    /**
     Send out request to a URL providing a completion handler.
     
     - Parameters:
     - request: The URLRequest required to send out the request.
     - completionHandler: The completion handler that handles the response and error.
     
     - Returns: Void.
     
     - Throws: `SARequestError`
     */
    
    // shared Instance of LDContentFetcher.
    public static let shared = SAContentFetcher()
    
    private override init() {}
    
    public func requestContent(request: URLRequest?, completionHandler: @escaping completionHandler) {
        
        // Creating a session
        let session = URLSession.shared
        
        let task = session.dataTask(with: request!) { (data, response, error) in
            
            // Check if request returns an error.
            if let localError = error as NSError? {
                
                switch localError.code {
                    
                default:
                    completionHandler(.failure(SARequestError.otherError(errorCode: localError.code)))
                    
                }
                return
            }
            
            // Request does not return error.
            if let localData = data, let urlResponse = response as? HTTPURLResponse {
                
                switch urlResponse.statusCode {
                    
                case SANetworkConstant.successfulResponseLowerRange, SANetworkConstant.successfulResponseUpperRange:
                    completionHandler(.success(localData))
                case SANetworkConstant.resourceNotFound:
                     completionHandler(.failure(SARequestError.encountered404))
                default:
                    completionHandler(.failure(SARequestError.otherError(errorCode: urlResponse.statusCode)))
                    
                }
            }
        }
        task.resume()
    }
}
