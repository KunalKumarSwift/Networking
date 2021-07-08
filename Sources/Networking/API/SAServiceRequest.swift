//
//  SAServiceRequest.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import UIKit

public typealias serviceRequestCompletionHandler = (Decodable?) -> Void

public protocol SAServiceRequest: SAURLBuilder {
    
    var contentFetcher: ContentFetcherProtocol? { get }
    
    func requestData<model: Decodable>(model m: model.Type,
                                       completionHandler: @escaping serviceRequestCompletionHandler) throws -> Void
    
    func requestData<model: Decodable>(withParameters parameters: [String: String],
                                       model m:  model.Type,
                                       completionHandler: @escaping serviceRequestCompletionHandler) throws -> Void
    
}

public extension SAServiceRequest {
    
    func requestData<model: Decodable>(model m: model.Type,
                                       completionHandler: @escaping serviceRequestCompletionHandler) throws -> Void {
        
        try self.requestData(withParameters: [:],
                             model: m.self,
                             completionHandler: completionHandler)
        
    }
    
    func requestData<model: Decodable>(withParameters parameters: [String: String],
                                       model m:  model.Type,
                                       completionHandler: @escaping serviceRequestCompletionHandler) throws -> Void {
        
        let requestBuilder: NetworkRequestBuilder = NetworkRequestBuilder()
        
        var request: URLRequest?
        
        do {
            request = try requestBuilder.buildURLRequest(withURLBuilder: self,
                                                         andParameters: parameters)
        } catch (let error as BuilderError) {
            completionHandler(nil)
            throw error
        }
        
        guard let urlRequest = request else {
            completionHandler(nil)
            return
        }
        
        self.contentFetcher?.requestContent(request: urlRequest) { (result) in
            switch result {
            case .success(let data):
                
                do {
                    let decodedModel = try JSONDecoder().decode(m.self, from: data)
                    completionHandler(decodedModel)
                } catch (let error) {
                    print(error.localizedDescription)
                    completionHandler(nil)
                }
                
            case .failure(let error):
                
                let title = "Sorry"
                var message = ""
                
                switch (error as SARequestError) {
                    
                case .encountered404:
                    
                    message = NSLocalizedString("NETWORK_RESPONSE_404",
                                                tableName: "NetworkResponse",
                                                bundle: Bundle.main,
                                                value: "",
                                                comment: "")
                    
                case.otherError(_):
                    
                    message = NSLocalizedString("NETWORK_RESPONSE_OTHER",
                                                tableName: "NetworkResponse",
                                                bundle: Bundle.main,
                                                value: "",
                                                comment: "")
                }
                // TODO: This should be done in the UI layer.
//                DispatchQueue.main.async {
//                    
//                    guard let appDel = UIApplication.shared.delegate, let window = appDel.window, let rootVC = window?.rootViewController else {
//                        completionHandler(nil)
//                        return
//                    }
//                    
//                    rootVC.showNetworkAlert(title: title,
//                                            message: message,
//                                            handler: nil)
//                    completionHandler(nil)
//                    
//                }
            }
        }
    }
}
