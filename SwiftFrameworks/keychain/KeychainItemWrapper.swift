//
//  KeychainItemWrapper.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/11/11.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//
//  import Security.framework
//

import Foundation
import Security

class KeychainItemWrapper: NSObject {
    
    var keychainItemData:NSMutableDictionary? = nil
    var genericPasswordQuery:NSMutableDictionary
    
    init(identifier:String, accessGroup:String?) {
        
        genericPasswordQuery = NSMutableDictionary()
        
        super.init()

        genericPasswordQuery.setObject(kSecClassGenericPassword, forKey: kSecClass as NSString)
        genericPasswordQuery.setObject(identifier, forKey: kSecAttrGeneric as NSString)
        
        if let group = accessGroup {
            // TODO: 增加宏判断模拟器模式什么都不做
            
            #if TARGET_IPHONE_SIMULATOR
                // Ignore the access group if running on the iPhone simulator.
                //
                // Apps that are built for the simulator aren't signed, so there's no keychain access group
                // for the simulator to check. This means that all apps can see all keychain items when run
                // on the simulator.
                //
                // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                // simulator will return -25243 (errSecNoAccessForItem).
            #else
                genericPasswordQuery.setObject(group, forKey: kSecAttrAccessGroup as NSString)
            #endif
        }
     
        genericPasswordQuery.setObject(kSecMatchLimitOne, forKey: kSecMatchLimit as NSString)
        genericPasswordQuery.setObject(kCFBooleanTrue, forKey: kSecReturnAttributes as NSString)

        let tempQuery = NSDictionary(dictionary: genericPasswordQuery)
        var outDictionaryRef:Unmanaged<AnyObject>?

        if !(SecItemCopyMatching(tempQuery,&outDictionaryRef) == noErr) {
            
            //let outDictionary = outDictionaryRef!.takeUnretainedValue() as NSMutableDictionary
//            outDictionaryRef!.release()
            
            resetKeychainItem()
            
            keychainItemData!.setObject(identifier, forKey: kSecAttrGeneric as NSString)
            
            if let group = accessGroup {
                // TODO: 增加宏判断模拟器模式什么都不做
                #if TARGET_IPHONE_SIMULATOR
                    // Ignore the access group if running on the iPhone simulator.
                    //
                    // Apps that are built for the simulator aren't signed, so there's no keychain access group
                    // for the simulator to check. This means that all apps can see all keychain items when run
                    // on the simulator.
                    //
                    // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                    // simulator will return -25243 (errSecNoAccessForItem).
                #else
                    keychainItemData!.setObject(group, forKey: kSecAttrAccessGroup as NSString)
                #endif
            }
        } else {
            let outDictionary = outDictionaryRef!.takeUnretainedValue() as NSMutableDictionary
            keychainItemData = secItemFormatToDictionary(outDictionary)
            outDictionaryRef!.release()
        }
        //if outDictionaryRef != nil { outDictionaryRef!.release() }
    }
    
    func setObject(inObject:AnyObject?, forKey key:NSString) {
        if inObject == nil { return }
        if let currentObject = keychainItemData!.objectForKey(key) as? NSObject {
            if !currentObject.isEqual(inObject) {
                keychainItemData!.setObject(inObject!, forKey: key)
                writeToKeychain()
            }
        }
    }
    
    // TODO: 需要继续写
    func objectForKey(key:AnyObject) -> AnyObject? {
        return keychainItemData?.objectForKey(key)
    }
    
    func resetKeychainItem() {
        var junk:OSStatus = noErr
        if keychainItemData == nil {
            keychainItemData = NSMutableDictionary()
        } else {
            let tempDictionary = dictionaryToSecItemFormat(keychainItemData!)
            junk = SecItemDelete(tempDictionary)
            assert(junk == noErr || junk == errSecItemNotFound, "Problem deleting current dictionary.")
        }
        
        // Default attributes for keychain item.
        keychainItemData!.setObject("", forKey: kSecAttrAccount as NSString)
        keychainItemData!.setObject("", forKey: kSecAttrLabel as NSString)
        keychainItemData!.setObject("", forKey: kSecAttrDescription as NSString)
        // Default data for keychain item.
        keychainItemData!.setObject("", forKey: kSecValueData as NSString)

    }
    
    private func dictionaryToSecItemFormat(dictionaryToConvert:NSDictionary) -> NSMutableDictionary {
        // The assumption is that this method will be called with a properly populated dictionary
        // containing all the right key/value pairs for a SecItem.
        
        // Create a dictionary to return populated with the attributes and data.
        
        var returnDictionary = NSMutableDictionary(dictionary: dictionaryToConvert)
        
        // Add the Generic Password keychain item class attribute.
        returnDictionary.setObject(kSecClassGenericPassword, forKey: kSecClass as NSString)
        
        // Convert the NSString to NSData to meet the requirements for the value type kSecValueData.
        // This is where to store sensitive data that should be encrypted.
        if let passwordString = dictionaryToConvert.objectForKey(kSecValueData) as? NSString {
            returnDictionary.setObject(passwordString.dataUsingEncoding(NSUTF8StringEncoding)!, forKey: kSecValueData as NSString)
        }
        
        return returnDictionary
    }
    
    private func secItemFormatToDictionary(dictionaryToConvert:NSDictionary) -> NSMutableDictionary {
        // The assumption is that this method will be called with a properly populated dictionary
        // containing all the right key/value pairs for the UI element.
        
        // Create a dictionary to return populated with the attributes and data.
        var returnDictionary = NSMutableDictionary(dictionary: dictionaryToConvert)
        
        // Add the proper search key and class attribute.
        returnDictionary.setObject(kCFBooleanTrue, forKey: kSecReturnData as NSString)
        returnDictionary.setObject(kSecClassGenericPassword, forKey: kSecClass as NSString)
        
        var passwordDataRef:Unmanaged<AnyObject>?
        // Acquire the password data from the attributes.
        if SecItemCopyMatching(returnDictionary,&passwordDataRef) == noErr {
            let passwordData = passwordDataRef!.takeUnretainedValue() as NSData
            
            // Remove the search, class, and identifier key/value, we don't need them anymore.
            returnDictionary.removeObjectForKey(kSecReturnData)
            
            // Add the password to the dictionary, converting from NSData to NSString.
            if let password = NSString(bytes: passwordData.bytes, length: passwordData.length, encoding: NSUTF8StringEncoding) {
                returnDictionary.setObject(password, forKey: kSecValueData as NSString)
            }
            
        } else {
            // Don't do anything if nothing is found.
            assert(false, "Serious error, no matching item found in the keychain.\n")
        }
        passwordDataRef?.release()

        return returnDictionary
    }
    
    private func writeToKeychain() {
        var attributesRef:Unmanaged<AnyObject>?
        
        if SecItemCopyMatching(genericPasswordQuery, &attributesRef) == noErr {
            let attributes = attributesRef!.takeUnretainedValue() as NSDictionary
            attributesRef!.release()
            attributesRef = nil
            // First we need the attributes from the Keychain.
            var updateItem = NSMutableDictionary(dictionary: attributes)
            // Second we need to add the appropriate search key/values.
            if let object: AnyObject = genericPasswordQuery.objectForKey(kSecClass) {
                updateItem.setObject(object, forKey: kSecClass as NSString)
            }
            
            var tempCheck = dictionaryToSecItemFormat(keychainItemData!)
            tempCheck.removeObjectForKey(kSecClass)
            
            #if TARGET_IPHONE_SIMULATOR
                // Remove the access group if running on the iPhone simulator.
                //
                // Apps that are built for the simulator aren't signed, so there's no keychain access group
                // for the simulator to check. This means that all apps can see all keychain items when run
                // on the simulator.
                //
                // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                // simulator will return -25243 (errSecNoAccessForItem).
                //
                // The access group attribute will be included in items returned by SecItemCopyMatching,
                // which is why we need to remove it before updating the item.
                tempCheck.removeObjectForKey(kSecAttrAccessGroup)
            #endif
            
            // An implicit assumption is that you can only update a single item at a time.
            let result = SecItemUpdate(updateItem, tempCheck)
            assert(result == noErr, "Couldn't update the Keychain Item.")
        } else {
            let result = SecItemAdd(dictionaryToSecItemFormat(keychainItemData!), nil)
            //assert(result == noErr, "Couldn't add the Keychain Item.")
        }
    }
}
