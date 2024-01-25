//
//  UploadS3.swift
//  UploadS3
//
//  Created by MY-YAZ on 23/1/2024.
//

import Foundation
import UIKit
import AWSS3 

typealias progressBlock = (_ progress: Double) -> Void 
typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void 

class UploadS3 {
    
    static let shared = UploadS3() 
    private init () { }
    let bucketName = "your bucket name" 
    
    
    func uploadImage(uploadFileURL: URL,image:UIImage, progress: progressBlock?, completion: completionBlock?) {
        
        let imageName = uploadFileURL.lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        // getting local path
        let localPath = (documentDirectory as NSString).appendingPathComponent(imageName)
        do {
            let data = image.pngData()
            try data!.write(to:URL(fileURLWithPath: localPath))
            
            let photoURL = URL(fileURLWithPath: localPath)
            
            self.uploadfile(fileUrl: photoURL, fileName: imageName, contenType: "image", progress: progress, completion: completion)
        } catch {
            let error = NSError(domain:"", code:402, userInfo:[NSLocalizedDescriptionKey: "invalid image"])
            completion?(nil, error)
        }
    }
    
    private func uploadfile(fileUrl: URL, fileName: String, contenType: String, progress: progressBlock?, completion: completionBlock?) {
        // Upload progress block
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
            }
        }
        // Completion block
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(fileName)
                    print("Uploaded to:\(String(describing: publicURL))")
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                }
            })
        }
        // Start uploading using AWSS3TransferUtility
        let awsTransferUtility = AWSS3TransferUtility.default()
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: fileName, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error is: \(error.localizedDescription)")
            }
            if let response = task.result {
                print("response is: \(response)")
            }
            return nil
        }
    }
}
